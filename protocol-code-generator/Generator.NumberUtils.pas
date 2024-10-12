unit Generator.NumberUtils;

{$MODE DELPHIUNICODE}{$H+}

interface

uses
  nullable;

function IsInteger(Input: string): Boolean;
function TryParseInt(Input: string): TNullable<Integer>;

implementation

uses
  SysUtils;

function IsInteger(Input: string): Boolean;
const
  CDigits = ['0'..'9'];
var
  Character: Char;
begin
  Result := Input <> '';
  for Character in Input do begin
    if not (Character in CDigits) then begin
      Result := False;
      Break;
    end;
  end;
end;

function TryParseInt(Input: string): TNullable<Integer>;
begin
  if IsInteger(Input) then begin
    Result := StrToInt(Input);
  end
  else begin
    Result := TNullable<Integer>.Empty;
  end;
end;

end.

