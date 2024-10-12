unit Generator.GuidUtils;

{$MODE DELPHIUNICODE}{$H+}

interface

uses
  SysUtils;

{ Generates deterministic GUIDs, as specified in @url(https://www.ietf.org/rfc/rfc4122.txt RFC 4122) (v5).

  @param(Value String to generate the GUID from)
  @returns(A deterministic GUID generated from the supplied string value) }
function NewDeterministicGuid(Value: string): TGUID;

implementation

uses
  sha1;

function NewDeterministicGuid(Value: string): TGUID;
const
  CNamespace: TGUID = '{36C4720F-5E92-4A76-BECE-8B21027FB86B}';
  CVersion = 5;
var
  NamespaceBytes: TBytes;
  ValueBytes: TBytes;
  CombinedBytes: TBytes;
  Hash: TSHA1Digest;
  ResultBytes: TBytes;
begin
  ValueBytes := TEncoding.UTF8.GetBytes(Value);
  NamespaceBytes := CNamespace.ToByteArray(TEndian.Big);

  CombinedBytes := Default(TBytes);
  SetLength(CombinedBytes, Length(NamespaceBytes) + Length(ValueBytes));
  Move(NamespaceBytes[0], CombinedBytes[0], Length(NamespaceBytes));
  Move(ValueBytes[0], CombinedBytes[Length(NamespaceBytes)], Length(ValueBytes));

  Hash := SHA1Buffer(CombinedBytes[0], Length(CombinedBytes));

  ResultBytes := Default(TBytes);
  SetLength(ResultBytes, 16);
  Move(Hash[0], ResultBytes[0], 16);

  ResultBytes[6] := (ResultBytes[6] and $0F) or (CVersion shl 4);
  ResultBytes[8] := (ResultBytes[8] and $3F) or $80;

  Result := TGUID.Create(ResultBytes, TEndian.Big);
end;

end.

