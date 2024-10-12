unit Generator.CodeGenerator;

{$MODE DELPHIUNICODE}{$H+}

interface

uses
  Generics.Collections,
  FileUtil,
  DOM,
  Generator.Types,
  Generator.PascalFile;

type
  TProtocolFile = class(TObject)
  strict private
    FUnitName: string;
    FFilename: string;
    FXMLDocument: TXMLDocument;
  public
    constructor Create(UnitName: string; Filename: string);
    destructor Destroy; override;
    property UnitName: string read FUnitName;
    property Filename: string read FFilename;
    property XMLDocument: TXMLDocument read FXMLDocument;
  end;

  TCodeGenerator = class(TObject)
  strict private
    FSourceDirectory: string;
    FOutputDirectory: string;
    FProtocolFiles: TObjectList<TProtocolFile>;
    FTypeFactory: TTypeFactory;
    procedure PrepareOutputDirectory;
    procedure IndexProtocolFiles;
    procedure IndexProtocolFile(Path: string);
    procedure GenerateSourceFiles;
    procedure GenerateSourceFile(ProtocolFile: TProtocolFile);
    procedure GenerateEnum(ProtocolEnum: TDOMElement; PascalUnit: TPascalUnit);
    procedure GenerateStruct(ProtocolStruct: TDOMElement; PascalUnit: TPascalUnit);
    procedure GeneratePacket(ProtocolPacket: TDOMElement; PascalUnit: TPascalUnit);
  public
    constructor Create(SourceDirectory: string; OutputDirectory: string);
    destructor Destroy; override;
    procedure Generate;
  end;

implementation

uses
  Classes,
  SysUtils,
  StrUtils,
  XMLRead,
  Generator.StringUtils,
  Generator.XmlUtils,
  Generator.PasDocUtils,
  Generator.ObjectCodeGenerator;

constructor TProtocolFile.Create(UnitName: string; Filename: string);
begin
  FUnitName := UnitName;
  FFilename := Filename;
  ReadXMLFile(FXMLDocument, Filename);
end;

destructor TProtocolFile.Destroy;
begin
  FreeAndNil(FXMLDocument);
end;

function ProcessDirectoryPath(Path: string): string;
begin
  Path := ExpandFileName(Path);
{$IFDEF MSWINDOWS}
  Path := StringReplace(Path, '\', '/', [rfReplaceAll]);
{$ENDIF}
  if not EndsStr('/', Path) then begin
    Path := Path + '/';
  end;
  Result := Path;
end;

constructor TCodeGenerator.Create(SourceDirectory: string; OutputDirectory: string);
begin
  FSourceDirectory := ProcessDirectoryPath(SourceDirectory);
  FOutputDirectory := ProcessDirectoryPath(OutputDirectory);
  FProtocolFiles := TObjectList<TProtocolFile>.Create(True);
  FTypeFactory := TTypeFactory.Create;
end;

destructor TCodeGenerator.Destroy;
begin
  FreeAndNil(FProtocolFiles);
  FreeAndNil(FTypeFactory);
end;

procedure TCodeGenerator.Generate;
begin
  try
    PrepareOutputDirectory;
    IndexProtocolFiles;
    GenerateSourceFiles;
  finally
    FProtocolFiles.Clear;
    FTypeFactory.Clear;
  end;
end;

procedure TCodeGenerator.PrepareOutputDirectory;
begin
  if DirectoryExists(FOutputDirectory) and not DeleteDirectory(FOutputDirectory, False) then begin
    raise Exception.CreateFmt('Failed to remove existing output directory: %s', [FOutputDirectory]);
  end;

  if not ForceDirectories(FOutputDirectory) then begin
    raise Exception.CreateFmt('Failed to create output directory: %s', [FOutputDirectory]);
  end;
end;

procedure TCodeGenerator.IndexProtocolFiles;
var
  Paths: TStringList;
  Path: string;
begin
  Paths := FindAllFiles(FSourceDirectory, 'protocol.xml');
  try
    for Path in Paths do begin
      IndexProtocolFile(Path);
    end;
  finally
    FreeAndNil(Paths);
  end;
end;

function GetProtocolElement(XMLDocument: TXMLDocument): TDOMElement;
var
  Children: TArray<TDOMElement>;
begin
  Children := GetElementsByTagName(XMLDocument, 'protocol');
  if Length(Children) <> 1 then begin
    raise EXmlError.create('Expected a root <protocol> element.');
  end;
  Result := Children[0];
end;

procedure TCodeGenerator.IndexProtocolFile(Path: string);
var
  DirectoryPath: string;
  RelativeDirectoryPath: string;
  PathPart: string;
  UnitName: string;
  ProtocolFile: TProtocolFile;
  Protocol: TDOMElement;
  EnumElements: TArray<TDOMElement>;
  StructElements: TArray<TDOMElement>;
  PacketElements: TArray<TDOMElement>;
  Element: TDOMElement;
  DeclaredPackets: THashSet<string>;
  PacketIdentifier: string;
begin
  WriteLn(Format('Indexing %s', [Path]));

  DirectoryPath := ExtractFilePath(Path);
  RelativeDirectoryPath := ExtractRelativePath(FSourceDirectory, DirectoryPath);
  RelativeDirectoryPath := StringReplace(RelativeDirectoryPath, '\', '/', [rfReplaceAll]);

  UnitName := 'EOLib.Protocol';

  for PathPart in SplitString(RelativeDirectoryPath, '/') do begin
    if PathPart <> '' then begin
      UnitName := UnitName + '.' + Capitalize(PathPart);
    end;
  end;

  ProtocolFile := TProtocolFile.Create(UnitName, Path);
  FProtocolFiles.Add(ProtocolFile);

  Protocol := GetProtocolElement(ProtocolFile.XMLDocument);
  EnumElements := GetElementsByTagName(Protocol, 'enum');
  StructElements := GetElementsByTagName(Protocol, 'struct');
  PacketElements := GetElementsByTagName(Protocol, 'packet');

  for Element in EnumElements do begin
    if not FTypeFactory.DefineCustomType(Element, UnitName) then begin
      raise Exception.CreateFmt('%s type cannot be redefined.', [GetRequiredStringAttribute(Element, 'name')]);
    end;
  end;

  for Element in StructElements do begin
    if not FTypeFactory.DefineCustomType(Element, UnitName) then begin
      raise Exception.CreateFmt('%s type cannot be redefined.', [GetRequiredStringAttribute(Element, 'name')]);
    end;
  end;

  DeclaredPackets := THashSet<string>.Create;
  try
    for Element in PacketElements do begin
      PacketIdentifier := Format(
        '%s_%s',
        [GetRequiredStringAttribute(Element, 'family'), GetRequiredStringAttribute(Element, 'action')]
      );
      if not DeclaredPackets.Add(PacketIdentifier) then begin
        raise Exception.CreateFmt('%s packet cannot be redefined in the same file.', [PacketIdentifier]);
      end;
    end;
  finally
    FreeAndNil(DeclaredPackets);
  end;
end;

procedure TCodeGenerator.GenerateSourceFiles;
var
  ProtocolFile: TProtocolFile;
begin
  for ProtocolFile in FProtocolFiles do begin
    GenerateSourceFile(ProtocolFile);
  end;
end;

procedure TCodeGenerator.GenerateSourceFile(ProtocolFile: TProtocolFile);
var
  PascalUnit: TPascalUnit;
  Protocol: TDOMElement;
  Element: TDOMElement;
begin
  PascalUnit := TPascalUnit.Create(ProtocolFile.UnitName);
  Protocol := GetProtocolElement(ProtocolFile.XMLDocument);
  try
    for Element in GetElementsByTagName(Protocol, 'enum') do begin
      GenerateEnum(Element, PascalUnit);
    end;

    for Element in GetElementsByTagName(Protocol, 'struct') do begin
      GenerateStruct(Element, PascalUnit);
    end;

    for Element in GetElementsByTagName(Protocol, 'packet') do begin
      GeneratePacket(Element, PascalUnit);
    end;

    PascalUnit.Write(FOutputDirectory);
  finally
    FreeAndNil(PascalUnit);
  end;
end;

procedure TCodeGenerator.GenerateEnum(ProtocolEnum: TDOMElement; PascalUnit: TPascalUnit);

  function GenerateEnumValues(EnumType: TEnumType): string;
  var
    ProtocolValue: TDOMElement;
    EnumValueName: string;
    EnumValue: TEnumType.TEnumValue;
    Values: TCodeBlock;
  begin
    Values := TCodeBlock.Create;
    try
      for ProtocolValue in GetElementsByTagName(ProtocolEnum, 'value') do begin
        if not Values.Empty then begin
          Values.AddLine(',');
        end;
        EnumValueName := GetRequiredStringAttribute(ProtocolValue, 'name');
        EnumValue := EnumType.FindEnumValueByName(EnumValueName);
        Values.Add(GeneratePasDoc(GetComment(ProtocolValue)));
        Values.Add(Format('%s = %d', [EnumValue.Name, EnumValue.OrdinalValue]));
      end;
      Result := Values.AsString;
    finally
      FreeAndNil(Values);
    end;
  end;

  function GenerateToStringCases(EnumType: TEnumType): string;
  var
    EnumValue: TEnumType.TEnumValue;
    Block: TCodeBlock;
  begin
    Block := TCodeBlock.Create;
    try
      for EnumValue in EnumType.Values do begin
        Block.AddLine(Format('%d: Result := ''%s'';', [EnumValue.OrdinalValue, EnumValue.Name]));
      end;
      Result := Block.AsString;
    finally
      FreeAndNil(Block);
    end;
  end;

var
  ProtocolName: string;
  EnumType: TType;
  EnumName: string;
  Slice: TPascalUnitSlice;
begin
  ProtocolName := GetRequiredStringAttribute(ProtocolEnum, 'name');
  EnumType := FTypeFactory.GetType(ProtocolName);

  if not (EnumType is TEnumType) then begin
    raise ETypeError.CreateFmt('%s is not an enum type.', [ProtocolName]);
  end;

  WriteLn(Format('Generating enum: %s', [ProtocolName]));

  EnumName := 'T' + EnumType.Name;

  Slice := TPascalUnitSlice.Create;

  Slice.TypeDeclarations.AddRange([
    TCodeBlock.Create
      .Add(GeneratePasDoc(GetComment(ProtocolEnum)))
      .AddLine(Format('%s = (', [EnumName]))
      .Indent
      .Add(GenerateEnumValues(EnumType as TEnumType))
      .AddLine
      .Unindent
      .AddLine(');'),
    TCodeBlock.Create
      .AddLine(Format('{ Helper for the %s enum type. }', [EnumName]))
      .AddLine(Format('%0:sHelper = record helper for %0:s', [EnumName]))
      .Indent
      .AddLine(Format('{ Converts an ordinal value to a @link(%s) enum value.', [EnumName]))
      .AddLine('  @param(Value The ordinal value to convert)')
      .AddLine(Format('  @returns(A @link(%s) enum value from the given ordinal value) }', [EnumName]))
      .AddLine(Format('class function FromInt(Value: Cardinal): %s; static; inline;', [EnumName]))
      .AddLine(Format('{ Converts the @link(%s) enum value to its corresponding ordinal value.', [EnumName]))
      .AddLine(Format('  @returns(The ordinal representation of the @link(%s) value)', [EnumName]))
      .AddLine('  @note(')
      .AddLine('    Protocol enums may hold out-of-bounds "unrecognized" values, which would cause')
      .AddLine('    range-checking errors with @code(Ord). @br @name is safe to use with range-checking enabled.) }')
      .AddLine('function ToInt: Cardinal; inline;')
      .AddLine(Format('{ Converts the @link(%s) enum value to its string representation.', [EnumName]))
      .AddLine(Format('  @returns(The string representation of the %s value) }', [EnumName]))
      .AddLine('function ToString: string;')
      .Unindent
      .AddLine('end;')
  ]);

  Slice.ImplementationBlock
    .AddLine(Format('{ %sHelper }', [EnumName]))
    .AddLine
    .AddLine(Format('class function %0:sHelper.FromInt(Value: Cardinal): %0:s;', [EnumName]))
    .AddLine('begin')
    .Indent
    .AddLine(Format('Result := %s(Value);', [EnumName]))
    .Unindent
    .AddLine('end;')
    .AddLine
    .AddLine(Format('function %0:sHelper.ToInt: Cardinal;', [EnumName]))
    .AddLine('begin')
    .Indent
    .AddLine('Result := Cardinal(Self);')
    .Unindent
    .AddLine('end;')
    .AddLine
    .AddLine(Format('function %0:sHelper.ToString: string;', [EnumName]))
    .AddLine('begin')
    .Indent
    .AddLine('case Self.ToInt of')
    .Indent
    .Add(GenerateToStringCases(EnumType as TEnumType))
    .AddLine('else begin')
    .Indent
    .AddLine('Result := Format(''Unrecognized(%d)'', [Self.ToInt]);')
    .Unindent
    .AddLine('end;')
    .Unindent
    .AddLine('end;')
    .Unindent
    .AddLine('end;')
    .AddUses('{$IFDEF FPC}SysUtils{$ELSE}System.SysUtils{$ENDIF}');

  PascalUnit.Add(Slice);
end;

procedure TCodeGenerator.GenerateStruct(ProtocolStruct: TDOMElement; PascalUnit: TPascalUnit);
var
  ProtocolName: string;
  StructType: TType;
  ObjectCodeGenerator: TObjectCodeGenerator;
  Slice: TPascalUnitSlice;
begin
  ProtocolName := GetRequiredStringAttribute(ProtocolStruct, 'name');
  StructType := FTypeFactory.GetType(ProtocolName);

  if not (StructType is TStructType) then begin
    raise ETypeError.CreateFmt('%s is not a struct type.', [StructType.Name]);
  end;

  WriteLn(Format('Generating struct: %s', [ProtocolName]));

  ObjectCodeGenerator := TObjectCodeGenerator.Create('T' + StructType.Name, 'I' + StructType.Name, FTypeFactory);
  try
    ObjectCodeGenerator.Data.PasDoc := GeneratePasDoc(GetComment(ProtocolStruct));
    ObjectCodeGenerator.GenerateInstructions(GetInstructions(ProtocolStruct));
    for Slice in ObjectCodeGenerator.GetTypes do begin
      PascalUnit.Add(Slice);
    end;
  finally
    FreeAndNil(ObjectCodeGenerator);
  end;
end;

procedure TCodeGenerator.GeneratePacket(ProtocolPacket: TDOMElement; PascalUnit: TPascalUnit);
  function MakePacketSuffix(UnitName: string): string;
  begin
    if SameStr(UnitName, 'EOLib.Protocol.Net.Client') then begin
      Result := 'ClientPacket';
    end
    else if SameStr(UnitName, 'EOLib.Protocol.Net.Server') then begin
      Result := 'ServerPacket';
    end
    else begin
      raise ECodeGenerationError.CreateFmt('Cannot create packet name suffix for unit name %s', [UnitName]);
    end;
  end;
var
  FamilyName: string;
  ActionName: string;
  TypeName: string;
  ObjectCodeGenerator: TObjectCodeGenerator;
  FamilyType: TType;
  ActionType: TType;
  Slice: TPascalUnitSlice;
begin
  FamilyName := GetRequiredStringAttribute(ProtocolPacket, 'family');
  ActionName := GetRequiredStringAttribute(ProtocolPacket, 'action');
  TypeName := FamilyName + ActionName + MakePacketSuffix(PascalUnit.UnitName);

  WriteLn(Format('Generating packet: %s', [TypeName]));

  ObjectCodeGenerator := TObjectCodeGenerator.Create('T' + TypeName, 'I' + TypeName, FTypeFactory);
  try
    ObjectCodeGenerator.Data.PasDoc := GeneratePasDoc(GetComment(ProtocolPacket));
    ObjectCodeGenerator.Data.AncestorInterfaces := ['IPacket'];
    ObjectCodeGenerator.GenerateInstructions(GetInstructions(ProtocolPacket));

    FamilyType := FTypeFactory.GetType('PacketFamily');
    if not (FamilyType is TEnumType) then begin
      raise ECodeGenerationError.Create('PacketFamily enum is missing');
    end;

    ActionType := FTypeFactory.GetType('PacketAction');
    if not (ActionType is TEnumType) then begin
      raise ECodeGenerationError.Create('PacketAction enum is missing');
    end;

    if (FamilyType as TEnumType).FindEnumValueByName(FamilyName).IsNull then begin
      raise ECodeGenerationError.CreateFmt('Unknown packet family "%s"', [FamilyName]);
    end;

    if (ActionType as TEnumType).FindEnumValueByName(ActionName).IsNull then begin
      raise ECodeGenerationError.CreateFmt('Unknown packet action "%s"', [ActionName]);
    end;

    ObjectCodeGenerator.Data.ClassMethodDeclarations
      .AddLine('{ Returns the packet family associated with this packet.')
      .AddLine('  @returns(The packet family associated with this packet) }')
      .AddLine('class function PacketFamily: TPacketFamily;')
      .AddLine('{ Returns the packet action associated with this packet.')
      .AddLine('  @returns(The packet action associated with this packet) }')
      .AddLine('class function PacketAction: TPacketAction;')
      .AddUses('EOLib.Protocol.Packet');

    ObjectCodeGenerator.Data.MethodDeclarations
      .AddLine('{ Returns the packet family associated with this packet.')
      .AddLine('  @returns(The packet family associated with this packet) }')
      .AddLine('function Family: TPacketFamily;')
      .AddLine('{ Returns the packet action associated with this packet.')
      .AddLine('  @returns(The packet action associated with this packet) }')
      .AddLine('function Action: TPacketAction;');

    ObjectCodeGenerator.Data.MethodImplementations.AddRange([
    TCodeBlock.Create
        .AddLine(Format('function %s.Family: TPacketFamily;', [ObjectCodeGenerator.Data.ClassTypeName]))
        .AddLine('begin')
        .Indent
        .AddLine('Result := PacketFamily;')
        .Unindent
        .AddLine('end;'),
      TCodeBlock.Create
        .AddLine(Format('function %s.Action: TPacketAction;', [ObjectCodeGenerator.Data.ClassTypeName]))
        .AddLine('begin')
        .Indent
        .AddLine('Result := PacketAction;')
        .Unindent
        .AddLine('end;'),
      TCodeBlock.Create
        .AddLine(Format('class function %s.PacketFamily: TPacketFamily;', [ObjectCodeGenerator.Data.ClassTypeName]))
        .AddLine('begin')
        .Indent
        .AddLine(Format('Result := TPacketFamily.%s;', [FamilyName]))
        .Unindent
        .AddLine('end;'),
      TCodeBlock.Create
        .AddLine(Format('class function %s.PacketAction: TPacketAction;', [ObjectCodeGenerator.Data.ClassTypeName]))
        .AddLine('begin')
        .Indent
        .AddLine(Format('Result := TPacketAction.%s;', [ActionName]))
        .Unindent
        .AddLine('end;')]);

    for Slice in ObjectCodeGenerator.GetTypes do begin
      PascalUnit.Add(Slice);
    end;
  finally
    FreeAndNil(ObjectCodeGenerator);
  end;
end;

end.

