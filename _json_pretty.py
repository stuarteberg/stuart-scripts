#!/usr/bin/env python
import sys
import json
import math
import re
from collections.abc import Mapping, Sequence


def main():
    f_in = sys.stdin
    f_out = sys.stdout

    if len(sys.argv) >= 2:
        f_in = open(sys.argv[1])

    if len(sys.argv) == 3:
        f_out = open(sys.argv[2])

    dump_json(json.load(f_in), f_out, unsplit_number_lists=True)


def dump_json(obj, f=None, indent=2, *, convert_nans=False, nullval="NaN", unsplit_number_lists=False, unsplit_int_lists=False):
    """
    Pretty-print the given object to json, either to a file or to a returned string.

    obj:
        Object to serialize to json.
        Permitted to contain numpy arrays.

    f:
        A file handle to write to, or a file path to create,
        or None, in which case the json is returned as a string.

    convert_nans:
        If True, replace NaN values with the provided nullval ("NaN" by default).
        Otherwise, the default python behavior is to write the word NaN
        (without quotes) into the json file, which is not compliant with
        the json standard.

    nullval:
        If convert_nans is True, then ``nullval`` is used to replace nan values.

    unsplit_number_lists:
        When pretty-printing, json.dump splits lists of integers or floats (e.g. [123, 456.0, -78e-9])
        across several lines.  For short lists, this is undesirable.
        This option will "unsplit" those lists, putting them back on a single line.
        This is implemented as a post-processing step using text matching.
        Might not be fast for huge files.

    unsplit_int_lists:
        Deprecated.  Like unsplit_number_lists, but only works for integers.

    Returns:
        Nothing if f was provided, otherwise returns a string.
    """
    if convert_nans:
        obj = _convert_nans(obj, nullval)

    kwargs = dict(
        indent=indent,
        allow_nan=not convert_nans
    )

    if unsplit_int_lists or unsplit_number_lists:
        json_text = json.dumps(obj, **kwargs)

        if unsplit_number_lists:
            json_text = unsplit_json_number_lists(json_text)
        elif unsplit_int_lists:
            json_text = unsplit_json_int_lists(json_text)

        if not json_text.endswith('\n'):
            json_text += '\n'

        if isinstance(f, str):
            with open(f, 'w') as f:
                f.write(json_text)
        elif f:
            f.write(json_text)
        else:
            return json_text
    else:
        if isinstance(f, str):
            with open(f, 'w') as f:
                json.dump(obj, f, **kwargs)
        elif f:
            json.dump(obj, f, **kwargs)
        else:
            return json.dumps(obj, **kwargs)


def convert_nans(o, nullval="NaN", _c=None):
    """
    Traverse the given collection-of-collections and
    replace all NaN values with the string "NaN".
    Also converts numpy arrays into lists.
    Intended for preprocessing objects before JSON serialization.
    """
    _c = _c or {}

    if isinstance(o, float) and math.isnan(o):
        return nullval
    elif isinstance(o, np.number):
        if np.isnan(o):
            return nullval
        return o.tolist()
    elif isinstance(o, (str, bytes)) or not isinstance(o, (Sequence, Mapping)):
        return o

    # Even though this function is meant mostly for JSON,
    # so we aren't likely to run into self-referencing
    # or cyclical object graphs, we handle that case by keeping
    # track of the objects we've already processed.
    if id(o) in _c:
        return _c[id(o)]

    if isinstance(o, np.ndarray):
        ret = []
        _c[id(o)] = ret
        ret.extend([convert_nans(x, nullval, _c) for x in o.tolist()])
    elif isinstance(o, Sequence):
        ret = []
        _c[id(o)] = ret
        ret.extend([convert_nans(x, nullval, _c) for x in o])
    elif isinstance(o, Mapping):
        ret = {}
        _c[id(o)] = ret
        ret.update({k: convert_nans(v, nullval, _c) for k,v in o.items()})
    else:
        raise RuntimeError(f"Can't handle {type(o)} object: {o}")

    return ret


# used in json_dump(), above
_convert_nans = convert_nans


def unsplit_json_int_lists(json_text):
    """
    When pretty-printing json data, json.dump() will split all lists across several lines.
    For small lists of integers (such as [x,y,z] points), that may not be desirable.
    This function "unsplits" all lists of integers and puts them back on a single line.

    Note:
        This implementation makes several passes over the input text,
        so it is not efficient for large inputs.

    Example:
        >>> s = '''\\
        ... {
        ...   "body": 123,
        ...   "supervoxel": 456,
        ...   "coord": [
        ...     123,
        ...     456,
        ...     789
        ...   ],
        ... }
        ... '''

        >>> u = unsplit_json_int_lists(s)
        >>> print(u)
        {
            "body": 123,
            "supervoxel": 456,
            "coord": [123, 456, 781],
        }

    """

    # Remove line break before first element
    json_text = re.sub(r'\[\s+(-?\d+),', r'[\1,', json_text)

    # Remove line breaks before middle elements
    json_text = re.sub(r'\n\s*(-?\d+),', r' \1,', json_text)

    # Remove line break before last element
    json_text = re.sub(r'\n\s*(-?\d+)\s*\]', r' \1]', json_text)

    # Fix single-element case: [ 123] -> [123]
    json_text = re.sub(r'\[\s+(-?\d+)\s*\]', r'[\1]', json_text)

    return json_text


def unsplit_json_number_lists(json_text):
    """
    When pretty-printing json data, json.dump() will split all lists across several lines.
    For small lists of integers (such as [x,y,z] points), that may not be desirable.
    This function "unsplits" all lists of numbers (int or float) and puts them back on a single line.

    Note:
        Unlike unsplit_json_int_lists above, this function reformats all numbers,
        including ints and floats.

    Note:
        This implementation makes several passes over the input text,
        so it is not efficient for large inputs.

    Example:
        >>> s = '''\\
        ... {
        ...   "body": 123,
        ...   "supervoxel": 456,
        ...   "properties": [
        ...     1.0,
        ...     5,
        ...     -1.9e-23
        ...   ],
        ... }
        ... '''

        >>> u = unsplit_json_int_lists(s)
        >>> print(u)
        {
            "body": 123,
            "supervoxel": 456,
            "properties": [1.0, 5, -1.9e-23]
        }
    """
    number = r'([-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?)'

    # Remove line break before first element
    json_text = re.sub(rf'\[\s+{number},', r'[\1,', json_text)

    # Remove line breaks before middle elements
    json_text = re.sub(rf'\n\s*{number},', r' \1,', json_text)

    # Remove line break before last element
    json_text = re.sub(rf'\n\s*{number}\s*\]', r' \1]', json_text)

    # Fix single-element case: [ 123] -> [123]
    json_text = re.sub(rf'\[\s+{number}\s*\]', r'[\1]', json_text)

    return json_text

if __name__ == "__main__":
    main()
