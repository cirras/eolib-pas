unit Generator.PasDocUtils;

{$MODE DELPHIUNICODE}
{$H+}

interface

function GeneratePasDoc(ProtocolComment: string): string; overload;
function GeneratePasDoc(ProtocolComment: string; Notes: array of string): string; overload;

implementation

uses
  SysUtils,
  Generics.Collections,
  Generator.StringUtils;

function GeneratePasDoc(ProtocolComment: string): string; overload;
begin
  Result := GeneratePasDoc(ProtocolComment, []);
end;

function GeneratePasDoc(ProtocolComment: string; Notes: array of string): string; overload;
var
  Lines: TList<string>;
  Line: string;
begin
  Lines := TList<string>.Create;
  try
    if ProtocolComment <> '' then begin
      for Line in Split(ProtocolComment, [LF]) do begin
        Lines.Add(Trim(Line));
      end;
    end;

    if Length(Notes) = 1 then begin
      Lines.Add(Format('@note(%s)', [Notes[0]]));
    end
    else if Length(Notes) > 1 then begin
      Lines.Add('@note(@unorderedList(');
      for Line in Notes do begin
        Lines.Add(Format('  @item(%s)', [Line]));
      end;
      Lines.Add('))');
    end;

    if Lines.Count > 0 then begin
      Result := '{ ' + Join(Lines.ToArray, CRLF + '  ') + ' }' + CRLF;
    end
    else begin
      Result := '';
    end;
  finally
    FreeAndNil(Lines);
  end;
end;

end.
