{
  lib,
  ...
}:
rec {
  lightenBy = num: clr: clr |> from |> lighten num |> toString;
  darkenBy = num: clr: clr |> from |> darken num |> toString;

  # parses either #RRGGBB or #RRGGBBAA
  from =
    str:
    assert (builtins.stringLength str == 7) || (builtins.stringLength str == 9);
    let
      strAt = offset: builtins.substring offset 2 str;
      r = strAt 1;
      g = strAt 3;
      b = strAt 5;
      a = strAt 7;
      parseHex =
        s:
        let
          res = (builtins.fromTOML ("x = 0x${s}")).x;
        in
        assert (res <= 255) && (res >= 0);
        res;
    in
    new {
      r = parseHex r;
      g = parseHex g;
      b = parseHex b;
      a = if a != "" then parseHex a else null;
    };

  formatHexDigit =
    length: digit:
    let
      toString = lib.toHexString digit;
      digitLen = builtins.stringLength toString;
    in
    assert (lib.assertMsg (digitLen <= length) "digit ${digit}");
    "${lib.strings.replicate (length - digitLen) "0"}${toString}";

  format =
    {
      r,
      g,
      b,
      a ? null,
      ...
    }:
    let
      fmt = formatHexDigit 2;
    in
    "#${fmt r}${fmt g}${fmt b}" + lib.optionalString (a != null) (fmt a);

  isValid =
    {
      r,
      g,
      b,
      a ? null,
      ...
    }:
    let
      validDigit = d: lib.assertMsg ((d <= 255) && (d >= 0)) "${d} is in the wrong range";
      interim = (validDigit r) && (validDigit g) && (validDigit b);
    in
    if a != null then interim && (validDigit a) else interim;

  new =
    clr@{
      r,
      g,
      b,
      a ? null,
    }:
    assert isValid clr;
    clr // { __toString = format; };

  cmap =
    fn:
    clr@{
      r,
      g,
      b,
      a ? null,
      ...
    }:
    let
      newColor = clr // {
        r = fn r;
        g = fn g;
        b = fn b;
      };
    in
    assert isValid newColor;
    newColor;

  lighten = amount: cmap (field: field + amount);
  darken = amount: cmap (field: field - amount);
}
