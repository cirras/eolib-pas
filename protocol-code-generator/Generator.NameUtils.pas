unit Generator.NameUtils;

{$MODE DELPHIUNICODE}{$H+}

interface

function SnakeCaseToPascalCase(Name: string): string;

implementation

function SnakeCaseToPascalCase(Name: string): string;
var
  UppercaseNext: Boolean;
  I: Integer;
  C: Char;
begin
  Result := '';
  UppercaseNext := True;

  for I := 1 to Length(Name) do begin
    C := Name[I];
    if C = '_' then begin
      UppercaseNext := Length(Result) > 0;
      Continue;
    end;

    if UppercaseNext then begin
      C := UpCase(C);
      UppercaseNext := False;
    end
    else begin
      C := LowerCase(C);
    end;

    Result := Result + C;
  end;
end;

end.

