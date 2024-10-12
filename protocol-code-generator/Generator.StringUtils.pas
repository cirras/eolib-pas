unit Generator.StringUtils;

{$MODE DELPHIUNICODE}{$H+}

interface

const
  LF = #10;
  CRLF = #13#10;

function Capitalize(Input: string): string;
function Split(Input: string; Delimiters: array of string): TArray<string>;
function Join(Input: array of string; Delimiter: string): string;
function ReplaceAll(Input: string; SearchString: string; Replacement: string): string;

implementation

function Capitalize(Input: string): string;
begin
  Result := Input;
  if Result <> '' then begin
    Result[1] := UpCase(Result[1]);
  end;
end;

function Split(Input: string; Delimiters: array of string): TArray<string>;

  function IsStringAtPos(Str: string; Pos: Integer): Boolean;
  var
    I: Integer;
  begin
    Result := Pos + Length(Str) <= Length(Input);
    if Result then begin
      for I := 1 to Length(Input) do begin
        Result := Str[I] = Input[Pos + I];
        if not Result then begin
          Break;
        end;
      end;
    end;
  end;

  function CheckDelimiter(StartPos: Integer): Integer;
  var
    I: Integer;
  begin
    Result := 0;

    for I := Low(Delimiters) to High(Delimiters) do begin
      if Delimiters[I] = '' then begin
        Continue;
      end;

      if Copy(Input, StartPos, Length(Delimiters[I])) = Delimiters[I] then begin
        Result := Length(Delimiters[i]);
        Exit;
      end;
    end;
  end;

var
  StartPos: Integer;
  DelimiterPos: Integer;
  DelimiterLength: Integer;
  Element: string;
begin
  Result := Default(TArray<string>);
  StartPos := 1;
  DelimiterPos := 1;

  while StartPos <= Length(Input) do begin
    DelimiterLength := CheckDelimiter(StartPos);

    if DelimiterLength > 0 then begin
      Element := Copy(Input, DelimiterPos, StartPos - DelimiterPos);
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := Element;

      StartPos := StartPos + DelimiterLength;
      DelimiterPos := StartPos;
    end
    else
      Inc(StartPos);
  end;

  Element := Copy(Input, DelimiterPos, Length(Input) - DelimiterPos + 1);
  SetLength(Result, Length(Result) + 1);
  Result[High(Result)] := Element;
end;

function Join(Input: array of string; Delimiter: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Length(Input) - 1 do begin
    if I > 0 then begin
      Result := Result + Delimiter;
    end;
    Result := Result + Input[I];
  end;
end;

function ReplaceAll(Input: string; SearchString: string; Replacement: string): string;
var
  Position: Integer;
begin
  Result := Input;
  Position := Pos(SearchString, Result);

  while Position > 0 do begin
    Delete(Result, Position, Length(SearchString));
    Insert(Replacement, Result, Position);
    Position := Pos(SearchString, Result, Position + Length(Replacement));
  end;
end;

end.

