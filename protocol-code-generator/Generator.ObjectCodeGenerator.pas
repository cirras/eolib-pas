unit Generator.ObjectCodeGenerator;

{$MODE DELPHIUNICODE}
{$H+}

interface

uses
  SysUtils,
  Classes,
  Generics.Collections,
  DOM,
  nullable,
  Generator.Types,
  Generator.PascalFile;

type
  ECodeGenerationError = class(Exception);

  TFieldData = record
  strict private
    FName: string;
    FType: TType;
    FOffset: Integer;
    FIsArray: Boolean;
  public
    constructor Create(Name: string; Type_: TType; Offset: Integer; IsArray: Boolean);
    property Name: string read FName;
    property Type_: TType read FType;
    property Offset: Integer read FOffset;
    property IsArray: Boolean read FIsArray;
  end;

  TVarData = record
    Name: string;
    Type_: string;
    InitializationStatement: string;
  end;

  TObjectGenerationContext = class(TObject)
  strict private
    FChunkedReadingEnabled: Boolean;
    FReachedOptionalField: Boolean;
    FReachedDummy: Boolean;
    FAccessibleFields: TDictionary<string, TFieldData>;
    FLengthFieldReferencedMap: TDictionary<string, Boolean>;
  public
    constructor Create; overload;
    constructor Create(Other: TObjectGenerationContext); overload;
    destructor Destroy; override;
    property ChunkedReadingEnabled: Boolean read FChunkedReadingEnabled write FChunkedReadingEnabled;
    property ReachedOptionalField: Boolean read FReachedOptionalField write FReachedOptionalField;
    property ReachedDummy: Boolean read FReachedDummy write FReachedDummy;
    property AccessibleFields: TDictionary<string, TFieldData> read FAccessibleFields write FAccessibleFields;
    property LengthFieldReferencedMap: TDictionary<string, Boolean>
        read FLengthFieldReferencedMap write FLengthFieldReferencedMap;
  end;

  TObjectGenerationData = class(TObject)
  strict private
    FClassTypeName: string;
    FInterfaceTypeName: string;
    FAncestorInterfaces: TArray<string>;
    FPasDoc: string;
    FFieldSignatures: TList<string>;
    FFields: TCodeBlock;
    FReadWriteMethodDeclarations: TCodeBlock;
    FMethodDeclarations: TCodeBlock;
    FClassMethodDeclarations: TCodeBlock;
    FProperties: TCodeBlock;
    FConstructor: TCodeBlock;
    FSerialize: TCodeBlock;
    FDeserialize: TCodeBlock;
    FSerializeVars: TDictionary<string, TVarData>;
    FDeserializeVars: TDictionary<string, TVarData>;
    FAuxillaryTypes: TList<TPascalUnitSlice>;
    FMethodImplementations: TList<TCodeBlock>;
    function GetSerializeVars: TArray<TVarData>;
    function GetDeserializeVars: TArray<TVarData>;
  public
    constructor Create(ClassTypeName: string; InterfaceTypeName: string);
    destructor Destroy; override;
    procedure AddSerializeVar(Name: string; Type_: string; InitializationStatement: string = '');
    procedure AddDeserializeVar(Name: string; Type_: string; InitializationStatement: string = '');
    property ClassTypeName: string read FClassTypeName;
    property InterfaceTypeName: string read FInterfaceTypeName;
    property AncestorInterfaces: TArray<string> read FAncestorInterfaces write FAncestorInterfaces;
    property PasDoc: string read FPasDoc write FPasDoc;
    property FieldSignatures: TList<string> read FFieldSignatures;
    property Fields: TCodeBlock read FFields;
    property Properties: TCodeBlock read FProperties;
    property ReadWriteMethodDeclarations: TCodeBlock read FReadWriteMethodDeclarations;
    property MethodDeclarations: TCodeBlock read FMethodDeclarations;
    property ClassMethodDeclarations: TCodeBlock read FClassMethodDeclarations;
    property Constructor_: TCodeBlock read FConstructor;
    property Serialize: TCodeBlock read FSerialize;
    property Deserialize: TCodeBlock read FDeserialize;
    property SerializeVars: TArray<TVarData> read GetSerializeVars;
    property DeserializeVars: TArray<TVarData> read GetDeserializeVars;
    property AuxillaryTypes: TList<TPascalUnitSlice> read FAuxillaryTypes;
    property MethodImplementations: TList<TCodeBlock> read FMethodImplementations;
  end;

  TFieldCodeGenerator = class(TObject)
  strict private
    FTypeFactory: TTypeFactory;
    FContext: TObjectGenerationContext;
    FData: TObjectGenerationData;
    FName: string;
    FTypeString: string;
    FLengthString: string;
    FPadded: Boolean;
    FOptional: Boolean;
    FHardcodedValue: string;
    FComment: string;
    FArrayField: Boolean;
    FDelimited: Boolean;
    FTrailingDelimiter: Boolean;
    FLengthField: Boolean;
    FLengthFieldBackReference: string;
    FOffset: Integer;

    procedure Validate;
    procedure ValidateSpecialFields;
    procedure ValidateOptionalField;
    procedure ValidateArrayField;
    procedure ValidateLengthField;
    procedure ValidateUnnamedField;
    procedure ValidateHardcodedValue;
    procedure ValidateUniqueName;
    procedure ValidateLengthAttribute;

    function GetAccessorPasDoc: string;

    procedure GenerateSerializeNullOptionalGuard;
    procedure GenerateSerializeLengthCheck;
    function GetWriteStatement: string;
    function GetWriteValueExpression: string;
    class function GetWriteStatementForBasicType(
        Type_: TBasicType;
        ValueExpression: string;
        LengthExpression: string;
        Padded: Boolean
    ): string;

    procedure GenerateDeserializeArray;
    function GetReadStatement: string;
    class function GetReadStatementForBasicType(Type_: TBasicType; LengthExpression: string; Padded: Boolean): string;

    function GetType: TType;
    function GetTypeLength: TLength;

    function GetDelphiFieldName: string;
    function GetDelphiTypeName(PreferInterface: Boolean = False): string;

    function GetSerializeLengthExpression: string;
    function GetDeserializeLengthExpression: string;
    class function GetLengthOffsetExpression(Offset: Integer): string;

  public
    constructor Create(
        TypeFactory: TTypeFactory;
        Context: TObjectGenerationContext;
        Data: TObjectGenerationData;
        Name: string;
        TypeString: string;
        LengthString: string;
        Padded: Boolean;
        Optional: Boolean;
        HardcodedValue: string;
        Comment: string;
        ArrayField: Boolean;
        Delimited: Boolean;
        TrailingDelimiter: Boolean;
        LengthField: Boolean;
        LengthFieldBackReference: string;
        Offset: Integer
    );

    procedure GenerateField;
    procedure GenerateSerialize;
    procedure GenerateDeserialize;

  public
    type
      TBuilder = record
      strict private
        FTypeFactory: TTypeFactory;
        FContext: TObjectGenerationContext;
        FData: TObjectGenerationData;
        FName: string;
        FType: string;
        FLength: string;
        FOffset: Integer;
        FPadded: Boolean;
        FOptional: Boolean;
        FHardcodedValue: string;
        FComment: string;
        FArrayField: Boolean;
        FLengthField: Boolean;
        FLengthFieldBackReference: string;
        FDelimited: Boolean;
        FTrailingDelimiter: Boolean;
      public
        constructor Create(TypeFactory: TTypeFactory; Context: TObjectGenerationContext; Data: TObjectGenerationData);
        function Name(Name: string): TBuilder;
        function Type_(Type_: string): TBuilder;
        function Length(Length: string): TBuilder;
        function Offset(Offset: Integer): TBuilder;
        function Padded(Padded: Boolean): TBuilder;
        function Optional(Optional: Boolean): TBuilder;
        function HardcodedValue(HardcodedValue: string): TBuilder;
        function Comment(Comment: string): TBuilder;
        function ArrayField(ArrayField: Boolean): TBuilder;
        function LengthField(LengthField: Boolean): TBuilder;
        function LengthFieldBackReference(LengthFieldBackReference: string): TBuilder;
        function Delimited(Delimited: Boolean): TBuilder;
        function TrailingDelimiter(TrailingDelimiter: Boolean): TBuilder;
        function Build: TFieldCodeGenerator;
      end;
  end;

  TSwitchCodeGenerator = class(TObject)
  strict private
    FFieldName: string;
    FTypeFactory: TTypeFactory;
    FContext: TObjectGenerationContext;
    FData: TObjectGenerationData;
    procedure GenerateCaseDataType(ProtocolCase: TDOMElement; CaseContext: TObjectGenerationContext);
    function GetFieldData: TFieldData;
    function GetInterfaceTypeName: string;
    function GetCaseDataFieldName: string;
    function GetCaseDataInterfaceTypeName(ProtocolCase: TDOMElement): string;
    function GetCaseDataClassTypeName(ProtocolCase: TDOMElement): string;
    function GetCaseValueDocsExpression(ProtocolCase: TDOMElement): string;
    function GetCaseValueExpression(ProtocolCase: TDOMElement): string;
  public
    constructor Create(
        FieldName: string;
        TypeFactory: TTypeFactory;
        Context: TObjectGenerationContext;
        Data: TObjectGenerationData
    );
    procedure GenerateCaseDataInterface;
    procedure GenerateCaseDataField;
    procedure GenerateSwitchStart;
    procedure GenerateSwitchEnd;
    function GenerateCase(ProtocolCase: TDOMElement; Start: Boolean): TObjectGenerationContext;
  end;

  TObjectCodeGenerator = class(TObject)
  strict private
    FClassTypeName: string;
    FInterfaceTypeName: string;
    FTypeFactory: TTypeFactory;
    FContext: TObjectGenerationContext;
    FOwnsContext: Boolean;
    FData: TObjectGenerationData;
    procedure GenerateInstruction(Instruction: TDOMElement; LengthFieldBackReferences: TDictionary<string, string>);
    procedure GenerateField(Instruction: TDOMElement);
    procedure GenerateArray(Instruction: TDOMElement);
    procedure GenerateLength(Instruction: TDOMElement; LengthFieldBackReferences: TDictionary<string, string>);
    procedure GenerateDummy(Instruction: TDOMElement);
    procedure GenerateSwitch(Instruction: TDOMElement);
    procedure GenerateChunked(Instruction: TDOMElement; LengthFieldBackReferences: TDictionary<string, string>);
    procedure GenerateBreak;
    function FieldCodeGeneratorBuilder: TFieldCodeGenerator.TBuilder;
    procedure CheckOptionalField(Optional: Boolean);
  public
    constructor Create(
        ClassTypeName: string;
        InterfaceTypeName: string;
        TypeFactory: TTypeFactory;
        Context: TObjectGenerationContext = nil
    );
    destructor Destroy; override;
    procedure GenerateInstructions(Instructions: TArray<TDOMElement>);
    function GetTypes: TArray<TPascalUnitSlice>;
    property Data: TObjectGenerationData read FData;
  end;

implementation

uses
  Math,
  StrUtils,
  Generator.NumberUtils,
  Generator.StringUtils,
  Generator.XmlUtils,
  Generator.PasDocUtils,
  Generator.NameUtils,
  Generator.GuidUtils;

function GetMaxValueOf(Type_: TIntegerType): Cardinal;
var
  Size: Cardinal;
begin
  Size := Type_.FixedSize.Value;
  Result := IfThen(SameStr(Type_.Name, 'byte'), 255, Trunc(IntPower(253, Size)) - 1);
end;

function EscapeKeyword(Name: string): string;
const
  C_Keywords: TArray<string> = ['type'];
begin
  Result := Name;
  if Lowercase(Result) in C_Keywords then begin
    Result := Result + '_';
  end;
end;

function CreateInterfaceGuid(QualifiedTypeName: string; FieldSignatures: TArray<string>): TGUID;
var
  TypeImage: string;
begin
  TypeImage := UpCase(QualifiedTypeName + '(' + Join(FieldSignatures, '; ') + ')');
  Result := NewDeterministicGuid(TypeImage);
end;

{ TFieldData }

constructor TFieldData.Create(Name: string; Type_: TType; Offset: Integer; IsArray: Boolean);
begin
  FName := Name;
  FType := Type_;
  FOffset := Offset;
  FIsArray := IsArray;
end;

{ TObjectGenerationContext }

constructor TObjectGenerationContext.Create;
begin
  FAccessibleFields := TDictionary<string, TFieldData>.Create;
  FLengthFieldReferencedMap := TDictionary<string, Boolean>.Create;
end;

function CopyDictionary<K, V>(Dictionary: TDictionary<K, V>): TDictionary<K, V>;
var
  Pair: TPair<K, V>;
begin
  Result := TDictionary<K, V>.Create;
  for Pair in Dictionary do begin
    Result.Add(Pair);
  end;
end;

constructor TObjectGenerationContext.Create(Other: TObjectGenerationContext);
begin
  FChunkedReadingEnabled := Other.ChunkedReadingEnabled;
  FReachedOptionalField := Other.ReachedOptionalField;
  FReachedDummy := Other.ReachedDummy;
  FAccessibleFields := CopyDictionary<string, TFieldData>(Other.AccessibleFields);
  FLengthFieldReferencedMap := CopyDictionary<string, Boolean>(Other.FLengthFieldReferencedMap);
end;

destructor TObjectGenerationContext.Destroy;
begin
  FreeAndNil(FAccessibleFields);
  FreeAndNil(FLengthFieldReferencedMap);
end;

{ TObjectGenerationData }

constructor TObjectGenerationData.Create(ClassTypeName: string; InterfaceTypeName: string);
begin
  FClassTypeName := ClassTypeName;
  FInterfaceTypeName := InterfaceTypeName;
  FFieldSignatures := TList<string>.Create;
  FFields := TCodeBlock.Create;
  FReadWriteMethodDeclarations := TCodeBlock.Create;
  FMethodDeclarations := TCodeBlock.Create;
  FClassMethodDeclarations := TCodeBlock.Create;
  FProperties := TCodeBlock.Create;
  FConstructor := TCodeBlock.Create;
  FSerialize := TCodeBlock.Create;
  FDeserialize := TCodeBlock.Create;
  FSerializeVars := TDictionary<string, TVarData>.Create;
  FDeserializeVars := TDictionary<string, TVarData>.Create;
  FAuxillaryTypes := TObjectList<TPascalUnitSlice>.Create;
  FMethodImplementations := TObjectList<TCodeBlock>.Create;

  AddSerializeVar('OldStringSanitizationMode', 'Boolean');
  AddDeserializeVar('OldChunkedReadingMode', 'Boolean');
  AddDeserializeVar('ReaderStartPosition', 'Cardinal');
end;

procedure TObjectGenerationData.AddSerializeVar(Name: string; Type_: string; InitializationStatement: string = '');
var
  VarData: TVarData;
begin
  VarData.Name := Name;
  VarData.Type_ := Type_;
  VarData.InitializationStatement := InitializationStatement;

  FSerializeVars.TryAdd(Name, VarData);
end;

procedure TObjectGenerationData.AddDeserializeVar(Name: string; Type_: string; InitializationStatement: string = '');
var
  VarData: TVarData;
begin
  VarData.Name := Name;
  VarData.Type_ := Type_;
  VarData.InitializationStatement := InitializationStatement;

  FDeserializeVars.TryAdd(Name, VarData);
end;

function TObjectGenerationData.GetSerializeVars: TArray<TVarData>;
begin
  Result := FSerializeVars.Values.ToArray;
end;

function TObjectGenerationData.GetDeserializeVars: TArray<TVarData>;
begin
  Result := FDeserializeVars.Values.ToArray;
end;

destructor TObjectGenerationData.Destroy;
begin
  FreeAndNil(FFieldSignatures);
  FreeAndNil(FFields);
  FreeAndNil(FMethodDeclarations);
  FreeAndNil(FClassMethodDeclarations);
  FreeAndNil(FProperties);
  FreeAndNil(FConstructor);
  FreeAndNil(FSerialize);
  FreeAndNil(FDeserialize);
  FreeAndNil(FSerializeVars);
  FreeAndNil(FDeserializeVars);
  FreeAndNil(FAuxillaryTypes);
  FreeAndNil(FMethodImplementations);
end;

{ TFieldCodeGenerator }

procedure TFieldCodeGenerator.Validate;
begin
  ValidateSpecialFields;
  ValidateOptionalField;
  ValidateArrayField;
  ValidateLengthField;
  ValidateUnnamedField;
  ValidateHardcodedValue;
  ValidateUniqueName;
  ValidateLengthAttribute;
end;

procedure TFieldCodeGenerator.ValidateSpecialFields;
begin
  if FArrayField and FLengthField then begin
    raise ECodeGenerationError.Create('A field cannot be both a length field and an array field.');
  end;
end;

procedure TFieldCodeGenerator.ValidateOptionalField;
begin
  if FOptional and (FName = '') then begin
    raise ECodeGenerationError.Create('Optional fields must specify a name.');
  end;
end;

procedure TFieldCodeGenerator.ValidateArrayField;
begin
  if FArrayField then begin
    if FName = '' then begin
      raise ECodeGenerationError.Create('Array fields must specify a name.');
    end;
    if FHardcodedValue <> '' then begin
      raise ECodeGenerationError.Create('Array fields may not specify hardcoded values.');
    end;
    if not FDelimited and not GetType.Bounded then begin
      raise ECodeGenerationError
          .CreateFmt('Unbounded element type %s forbidden in non-delimited array.', [FTypeString]);
    end;
  end
  else if FDelimited then begin
    raise ECodeGenerationError.Create('Only arrays can be delimited.');
  end;
end;

procedure TFieldCodeGenerator.ValidateLengthField;
var
  FieldType: TType;
begin
  if FLengthField then begin
    if FName = '' then begin
      raise ECodeGenerationError.Create('Length fields must specify a name.');
    end;
    if FHardcodedValue <> '' then begin
      raise ECodeGenerationError.Create('Length fields may not specify hardcoded values.');
    end;
    if FLengthFieldBackReference = '' then begin
      raise ECodeGenerationError.Create('Length fields must be referenced.');
    end;
    FieldType := GetType;
    if not (FieldType is TIntegerType) then begin
      raise ECodeGenerationError
          .CreateFmt('%s is not a numeric type, so it is not allowed for a length field.', [FieldType.Name]);
    end;
  end
  else if FOffset <> 0 then begin
    raise ECodeGenerationError.Create('Only length fields can have an offset.');
  end;
end;

procedure TFieldCodeGenerator.ValidateUnnamedField;
begin
  if FName = '' then begin
    if FHardcodedValue = '' then begin
      raise ECodeGenerationError.Create('Unnamed fields must specify a hardcoded field value.');
    end;
    if FOptional then begin
      raise ECodeGenerationError.Create('Unnamed fields may not be optional.');
    end;
  end;
end;

procedure TFieldCodeGenerator.ValidateHardcodedValue;
var
  FieldType: TType;
  LengthInt: TNullable<Integer>;
begin
  if FHardcodedValue <> '' then begin
    FieldType := GetType;

    if FieldType is TStringType then begin
      LengthInt := TryParseInt(FLengthString);
      if LengthInt.HasValue and (LengthInt.Value <> Length(FHardcodedValue)) then begin
        raise ECodeGenerationError
            .CreateFmt('Expected length of %s for hardcoded string value "%s".', [LengthInt.Value, FHardcodedValue]);
      end;
    end;

    if not (FieldType is TBasicType) then begin
      raise ECodeGenerationError
          .CreateFmt('Hardcoded field values are not allowed for %s fields (must be a basic type).', [FieldType.Name]);
    end;
  end;
end;

procedure TFieldCodeGenerator.ValidateUniqueName;
begin
  if (FName <> '') and FContext.AccessibleFields.ContainsKey(FName) then begin
    raise ECodeGenerationError.CreateFmt('Cannot redefine %s field.', [FName]);
  end;
end;

procedure TFieldCodeGenerator.ValidateLengthAttribute;
var
  AlreadyReferenced: Boolean;
begin
  if FLengthString <> '' then begin
    if not IsInteger(FLengthString) and not FContext.LengthFieldReferencedMap.ContainsKey(FLengthString) then begin
      raise ECodeGenerationError
          .CreateFmt('Length attribute "%s" must be a numeric literal, or refer to a length field.', [FLengthString]);
    end;

    if FContext.LengthFieldReferencedMap.TryGetValue(FLengthString, AlreadyReferenced) and AlreadyReferenced then begin
      raise ECodeGenerationError
          .CreateFmt('Length field "%s" must not be referenced by multiple fields.', [FLengthString]);
    end;
  end;
end;

function TFieldCodeGenerator.GetAccessorPasDoc: string;
var
  Notes: TList<string>;
  LengthDescription: string;
  FieldData: TFieldData;
  MaxValue: Cardinal;
  FieldType: TType;
  ValueDescription: string;
begin
  Notes := TList<string>.Create;
  try
    if FLengthString <> '' then begin
      LengthDescription := '';
      if FContext.AccessibleFields.TryGetValue(FLengthString, FieldData) then begin
        MaxValue := GetMaxValueOf(FieldData.Type_ as TIntegerType) + FieldData.Offset;
        LengthDescription := Format('%u or less', [MaxValue]);
      end
      else begin
        LengthDescription := Format('@code(%s)', [FLengthString]);
        if FPadded then begin
          LengthDescription := LengthDescription + ' or less';
        end;
      end;
      Notes.Add('Length must be ' + LengthDescription);
    end;

    FieldType := GetType;
    if FieldType is TIntegerType then begin
      ValueDescription := IfThen(FArrayField, 'Element value', 'Value');
      Notes.Add(Format('%s range is 0-%u', [ValueDescription, GetMaxValueOf(FieldType as TIntegerType)]));
    end;

    Result := GeneratePasDoc(FComment, Notes.ToArray);
  finally
    FreeAndNil(Notes);
  end;
end;

procedure TFieldCodeGenerator.GenerateSerializeNullOptionalGuard;
begin
  if not FOptional then begin
    Exit;
  end;

  if FContext.ReachedOptionalField then begin
    FData.Serialize.AddLine(
        Format('ReachedEmptyOptional := ReachedEmptyOptional or F%s.IsEmpty;', [GetDelphiFieldName])
    );
  end
  else begin
    FData.Serialize.AddLine(Format('ReachedEmptyOptional := F%s.IsEmpty;', [GetDelphiFieldName]));
    FData.AddSerializeVar('ReachedEmptyOptional', 'Boolean');
  end;
  FData.Serialize.AddLine('if not ReachedEmptyOptional then begin').Indent;
end;

procedure TFieldCodeGenerator.GenerateSerializeLengthCheck;
var
  LengthExpression: string;
  FieldData: TFieldData;
  DelphiName: string;
  VariableSize: Boolean;
  LengthCheckOperator: string;
  ExpectedLengthDescription: string;
  ErrorMessage: string;
begin
  if FName = '' then begin
    Exit;
  end;

  if not FLengthField and FContext.AccessibleFields.ContainsKey(FLengthString) then begin
    // Rely on the length check generated earlier for the length field.
    Exit;
  end;

  if FLengthField then begin
    FieldData := FContext.AccessibleFields[FName];
    LengthExpression := IntToStr(GetMaxValueOf(FieldData.Type_ as TIntegerType) + FieldData.Offset);
    VariableSize := True;
  end
  else begin
    LengthExpression := FLengthString;
    VariableSize := FPadded;
  end;

  if LengthExpression = '' then begin
    Exit;
  end;

  if FLengthField then begin
    DelphiName := SnakeCaseToPascalCase(FLengthFieldBackReference);
  end
  else begin
    DelphiName := GetDelphiFieldName;
  end;

  LengthCheckOperator := IfThen(VariableSize, '>', '<>');
  ExpectedLengthDescription := IfThen(VariableSize, '%d or less', 'exactly %d');

  ErrorMessage :=
      'Expected length of ' + EscapeKeyword(DelphiName) + ' to be ' + ExpectedLengthDescription + ', got %d.';

  (FData.Serialize)
      .AddLine(Format('if Length(F%s) %s %s then begin', [DelphiName, LengthCheckOperator, LengthExpression]))
      .Indent
      .AddLine(
          Format(
              'raise ESerializationError.CreateFmt(''%s'', [%s, Length(F%s)]);',
              [ErrorMessage, LengthExpression, DelphiName]
          ))
      .Unindent
      .AddLine('end;')
      .AddUses('EOLib.Protocol.Errors');
end;

function TFieldCodeGenerator.GetWriteStatement: string;
var
  RealType: TType;
  Type_: TType;
  ValueExpression: string;
begin
  RealType := GetType;
  Type_ := RealType;

  if Type_ is IHasUnderlyingType then begin
    Type_ := (Type_ as IHasUnderlyingType).UnderlyingType;
  end;

  ValueExpression := GetWriteValueExpression + GetLengthOffsetExpression(-FOffset);

  if Type_ is TBasicType then begin
    Result :=
        GetWriteStatementForBasicType(Type_ as TBasicType, ValueExpression, GetSerializeLengthExpression, FPadded);
  end
  else if Type_ is TBlobType then begin
    Result := Format('Writer.AddBytes(%s);', [ValueExpression]);
  end
  else if Type_ is TStructType then begin
    Result := Format('%s.Serialize(Writer);', [ValueExpression]);
  end
  else begin
    raise EAssertionFailed.Create('Unhandled TType');
  end;
end;

function TFieldCodeGenerator.GetWriteValueExpression: string;
var
  Type_: TType;
begin
  Type_ := GetType;
  if FName = '' then begin
    if Type_ is TIntegerType then begin
      if IsInteger(FHardcodedValue) then begin
        Result := FHardcodedValue;
      end
      else begin
        raise ECodeGenerationError.CreateFmt('"%s" is not a valid integer value.', [FHardcodedValue]);
      end;
    end
    else if Type_ is TBoolType then begin
      if SameStr(FHardcodedValue, 'false') then begin
        Result := '0';
      end
      else if SameStr(FHardcodedValue, 'true') then begin
        Result := '1';
      end
      else begin
        raise ECodeGenerationError.CreateFmt('"%s" is not a valid bool value.', [FHardcodedValue]);
      end
    end
    else if Type_ is TStringType then begin
      Result := '''' + FHardcodedValue + '''';
    end
    else begin
      raise EAssertionFailed.Create('Unhandled TBasicType');
    end;
  end
  else if FLengthField then begin
    Result := Format('Length(F%s)', [SnakeCaseToPascalCase(FLengthFieldBackReference)]);
  end
  else begin
    Result := 'F' + SnakeCaseToPascalCase(FName);

    if FOptional then begin
      Result := Result + '.Get';
    end;

    if FArrayField then begin
      Result := Result + '[I]';
    end;

    if Type_ is TEnumType then begin
      Result := Result + '.ToInt';
    end
    else if Type_ is TBoolType then begin
      Result := Format('Cardinal(%s)', [Result]);
    end;
  end;
end;

class function TFieldCodeGenerator.GetWriteStatementForBasicType(
    Type_: TBasicType;
    ValueExpression: string;
    LengthExpression: string;
    Padded: Boolean
): string;
begin
  if SameStr(Type_.Name, 'byte') then begin
    Result := Format('Writer.AddByte(%s);', [ValueExpression]);
  end
  else if SameStr(Type_.Name, 'char') then begin
    Result := Format('Writer.AddChar(%s);', [ValueExpression]);
  end
  else if SameStr(Type_.Name, 'short') then begin
    Result := Format('Writer.AddShort(%s);', [ValueExpression]);
  end
  else if SameStr(Type_.Name, 'three') then begin
    Result := Format('Writer.AddThree(%s);', [ValueExpression]);
  end
  else if SameStr(Type_.Name, 'int') then begin
    Result := Format('Writer.AddInt(%s);', [ValueExpression]);
  end
  else if SameStr(Type_.Name, 'string') then begin
    if LengthExpression = '' then begin
      Result := Format('Writer.AddString(%s);', [ValueExpression]);
    end
    else begin
      Result :=
          Format('Writer.AddFixedString(%s, %s, %s);', [ValueExpression, LengthExpression, BoolToStr(Padded, True)]);
    end;
  end
  else if SameStr(Type_.Name, 'encoded_string') then begin
    if LengthExpression = '' then begin
      Result := Format('Writer.AddEncodedString(%s);', [ValueExpression]);
    end
    else begin
      Result :=
          Format(
              'Writer.AddFixedEncodedString(%s, %s, %s);',
              [ValueExpression, LengthExpression, BoolToStr(Padded, True)]
          );
    end;
  end
  else begin
    raise EAssertionFailed.Create('Unhandled TBasicType');
  end;
end;

procedure TFieldCodeGenerator.GenerateDeserializeArray;
var
  DelphiName: string;
  ArrayLengthExpression: string;
  ForLoopFinalValue: string;
  ElementSize: TNullable<Integer>;
  ListVariableName: string;
  NeedsGuard: Boolean;
begin
  DelphiName := GetDelphiFieldName;
  ArrayLengthExpression := GetDeserializeLengthExpression;

  if (ArrayLengthExpression = '') and not FDelimited then begin
    ElementSize := GetType.FixedSize;
    if ElementSize.HasValue then begin
      ArrayLengthExpression := DelphiName + 'Length';
      FData.AddDeserializeVar(ArrayLengthExpression, 'Cardinal');
      FData.Deserialize.AddLine(Format('%s := Reader.Remaining div %d;', [ArrayLengthExpression, ElementSize.Value]));
    end;
  end;

  ListVariableName := DelphiName + 'List';
  FData.AddDeserializeVar(ListVariableName, Format('TList<%s>', [GetDelphiTypeName(True)]));

  (FData.Deserialize)
      .AddLine(Format('%s := TList<%s>.Create;', [ListVariableName, GetDelphiTypeName(True)]))
      .AddLine('try')
      .Indent
      .AddUses('Generics.Collections');

  if ArrayLengthExpression = '' then begin
    FData.Deserialize.AddLine('while Reader.Remaining > 0 do begin').Indent;
  end
  else begin
    ForLoopFinalValue := ArrayLengthExpression;
    if IsInteger(ForLoopFinalValue) then begin
      ForLoopFinalValue := IntToStr(StrToInt(ForLoopFinalValue) - 1);
    end
    else begin
      ForLoopFinalValue := ForLoopFinalValue + ' - 1';
    end;
    FData.AddDeserializeVar('I', 'Cardinal');
    FData.Deserialize.AddLine(Format('for I := 0 to %s do begin', [ForLoopFinalValue])).Indent;
  end;

  FData.Deserialize.AddLine(GetReadStatement);

  if FDelimited then begin
    NeedsGuard := not FTrailingDelimiter and (ArrayLengthExpression <> '');
    if NeedsGuard then begin
      FData.Deserialize.AddLine(Format('if I + 1 < %s then begin', [ArrayLengthExpression])).Indent;
    end;

    FData.Deserialize.AddLine('Reader.NextChunk;');

    if NeedsGuard then begin
      FData.Deserialize.Unindent.AddLine('end;');
    end;
  end;

  (FData.Deserialize)
      .Unindent
      .AddLine('end;')
      .AddLine(Format('Result.F%s := %s.ToArray;', [DelphiName, ListVariableName]))
      .Unindent
      .AddLine('finally')
      .Indent
      .AddLine(Format('FreeAndNil(%s);', [ListVariableName]))
      .Unindent
      .AddLine('end;')
      .AddUses('{$IFDEF FPC}SysUtils{$ELSE}System.SysUtils{$ENDIF}')
end;

function TFieldCodeGenerator.GetReadStatement: string;
var
  RealType: TType;
  Type_: TType;
  LengthExpression: string;
  ReadBasicType: string;
  OffsetExpression: string;
begin
  RealType := GetType;
  Type_ := RealType;
  if Type_ is IHasUnderlyingType then begin
    Type_ := (Type_ as IHasUnderlyingType).UnderlyingType;
  end;

  if FArrayField then begin
    Result := Format('%sList.Add(', [GetDelphiFieldName]);
  end
  else if FLengthField then begin
    FData.AddDeserializeVar(GetDelphiFieldName, GetDelphiTypeName);
    Result := Format('%s := ', [GetDelphiFieldName]);
  end
  else if FName <> '' then begin
    Result := Format('Result.F%s := ', [GetDelphiFieldName]);
  end;

  if Type_ is TBasicType then begin
    LengthExpression := IfThen(FArrayField, '', GetDeserializeLengthExpression);
    ReadBasicType := GetReadStatementForBasicType(Type_ as TBasicType, LengthExpression, FPadded);

    OffsetExpression := GetLengthOffsetExpression(FOffset);
    if OffsetExpression <> '' then begin
      ReadBasicType := ReadBasicType + OffsetExpression;
    end;

    if RealType is TBoolType then begin
      Result := Result + Format('%s <> 0', [ReadBasicType]);
    end
    else if RealType is TEnumType then begin
      Result := Result + Format('T%s.FromInt(%s)', [RealType.Name, ReadBasicType]);
    end
    else begin
      Result := Result + ReadBasicType;
    end;
  end
  else if Type_ is TBlobType then begin
    Result := Result + 'Reader.GetBytes(Reader.Remaining)';
  end
  else if Type_ is TStructType then begin
    Result := Result + Format('T%s.Deserialize(Reader)', [Type_.Name]);
  end
  else begin
    raise EAssertionFailed.Create('Unhandled Type');
  end;

  if FArrayField then begin
    Result := Result + ')';
  end;

  Result := Result + ';';
end;

class function TFieldCodeGenerator.GetReadStatementForBasicType(
    Type_: TBasicType;
    LengthExpression: string;
    Padded: Boolean
): string;
begin
  if SameStr(Type_.Name, 'byte') then begin
    Result := 'Reader.GetByte';
  end
  else if SameStr(Type_.Name, 'char') then begin
    Result := 'Reader.GetChar';
  end
  else if SameStr(Type_.Name, 'short') then begin
    Result := 'Reader.GetShort';
  end
  else if SameStr(Type_.Name, 'three') then begin
    Result := 'Reader.GetThree';
  end
  else if SameStr(Type_.Name, 'int') then begin
    Result := 'Reader.GetInt';
  end
  else if SameStr(Type_.Name, 'string') then begin
    if LengthExpression = '' then begin
      Result := 'Reader.GetString';
    end
    else begin
      Result := Format('Reader.GetFixedString(%s, %s)', [LengthExpression, BoolToStr(Padded, True)]);
    end;
  end
  else if SameStr(Type_.Name, 'encoded_string') then begin
    if LengthExpression = '' then begin
      Result := 'Reader.GetEncodedString';
    end
    else begin
      Result := Format('Reader.GetFixedEncodedString(%s, %s)', [LengthExpression, BoolToStr(Padded, True)]);
    end;
  end
  else begin
    raise EAssertionFailed.Create('Unhandled TBasicType');
  end;
end;

function TFieldCodeGenerator.GetType: TType;
begin
  Result := FTypeFactory.GetType(FTypeString, GetTypeLength);
end;

function TFieldCodeGenerator.GetTypeLength: TLength;
begin
  if not FArrayField and (FLengthString <> '') then begin
    Result := TLength.FromString(FLengthString);
  end
  else begin
    Result := TLength.Unspecified;
  end;
end;

function TFieldCodeGenerator.GetDelphiFieldName: string;
begin
  Result := SnakeCaseToPascalCase(FName);
end;

function TFieldCodeGenerator.GetDelphiTypeName(PreferInterface: Boolean = False): string;
var
  Type_: TType;
begin
  Type_ := GetType;
  if Type_ is TIntegerType then begin
    Result := 'Cardinal';
  end
  else if Type_ is TStringType then begin
    Result := 'string';
  end
  else if Type_ is TBoolType then begin
    Result := 'Boolean';
  end
  else if Type_ is TBlobType then begin
    Result := 'TArray<Byte>';
  end
  else if Type_ is TCustomType then begin
    Result := Type_.Name;
    if PreferInterface and (Type_ is TStructType) then begin
      Result := 'I' + Result;
    end
    else begin
      Result := 'T' + Result;
    end;
  end
  else begin
    raise EAssertionFailed.Create('Unhandled TType');
  end;
end;

function TFieldCodeGenerator.GetSerializeLengthExpression: string;
begin
  Result := FLengthString;
  if (Result <> '') and not IsInteger(Result) then begin
    Result := Format('Length(F%s)', [SnakeCaseToPascalCase(FName)]);
  end;
end;

function TFieldCodeGenerator.GetDeserializeLengthExpression: string;
var
  FieldData: TFieldData;
begin
  Result := FLengthString;
  if (Result <> '') and not IsInteger(Result) then begin
    if not FContext.AccessibleFields.TryGetValue(Result, FieldData) then begin
      raise ECodeGenerationError.CreateFmt('Referenced %s field is not accessible.', [Result])
    end;
    Result := EscapeKeyword(SnakeCaseToPascalCase(FieldData.Name));
  end;
end;

class function TFieldCodeGenerator.GetLengthOffsetExpression(Offset: Integer): string;
begin
  if Offset <> 0 then begin
    Result := IfThen(Offset > 0, ' + ', ' - ') + IntToStr(Abs(Offset));
  end
  else begin
    Result := '';
  end;
end;

constructor TFieldCodeGenerator.Create(
    TypeFactory: TTypeFactory;
    Context: TObjectGenerationContext;
    Data: TObjectGenerationData;
    Name: string;
    TypeString: string;
    LengthString: string;
    Padded: Boolean;
    Optional: Boolean;
    HardcodedValue: string;
    Comment: string;
    ArrayField: Boolean;
    Delimited: Boolean;
    TrailingDelimiter: Boolean;
    LengthField: Boolean;
    LengthFieldBackReference: string;
    Offset: Integer
);
begin
  FTypeFactory := TypeFactory;
  FContext := Context;
  FData := Data;
  FName := Name;
  FTypeString := TypeString;
  FLengthString := LengthString;
  FPadded := Padded;
  FOptional := Optional;
  FHardcodedValue := HardcodedValue;
  FComment := Comment;
  FArrayField := ArrayField;
  FDelimited := Delimited;
  FTrailingDelimiter := TrailingDelimiter;
  FLengthField := LengthField;
  FLengthFieldBackReference := LengthFieldBackReference;
  FOffset := Offset;

  Validate;
end;

procedure TFieldCodeGenerator.GenerateField;
var
  DelphiName: string;
  EscapedDelphiName: string;
  FieldType: TType;
  DelphiTypeName: string;
  InitialValue: string;
  PropertyDeclaration: string;
begin
  if FName = '' then begin
    Exit;
  end;

  DelphiName := GetDelphiFieldName;
  EscapedDelphiName := EscapeKeyword(DelphiName);
  FieldType := GetType;
  DelphiTypeName := GetDelphiTypeName(True);

  if FArrayField then begin
    DelphiTypeName := Format('TArray<%s>', [DelphiTypeName]);
  end;

  if FOptional then begin
    DelphiTypeName := Format('TOptional<%s>', [DelphiTypeName]);
    FData.Fields.AddUses('EOLib.Utils.Optional');
  end;

  FData.FieldSignatures.Add(DelphiName + ': ' + DelphiTypeName);

  if FHardcodedValue <> '' then begin
    InitialValue := FHardcodedValue;
    if FieldType is TStringType then begin
      InitialValue := '''' + ReplaceAll(InitialValue, '''', '''''') + '''';
    end;
    FData.Constructor_.AddLine(Format('F%s := %s;', [DelphiName, InitialValue]));
  end;

  FContext.AccessibleFields.Add(FName, TFieldData.Create(FName, FieldType, FOffset, FArrayField));

  if FieldType is TCustomType then begin
    FData.Fields.AddUses((FieldType as TCustomType).UnitName);
  end;

  if FLengthField then begin
    FContext.LengthFieldReferencedMap.Add(FName, False);
    Exit;
  end;

  FData.Fields.AddLine(Format('F%s: %s;', [DelphiName, DelphiTypeName]));

  FData.ReadWriteMethodDeclarations.AddLine(Format('function _Get%s: %s;', [DelphiName, DelphiTypeName]));
  FData.MethodImplementations.Add(
      (TCodeBlock.Create)
          .AddLine(Format('function %s._Get%s: %s;', [FData.ClassTypeName, DelphiName, DelphiTypeName]))
          .AddLine('begin')
          .Indent
          .AddLine(Format('Result := F%s;', [DelphiName]))
          .Unindent
          .AddLine('end;')
  );

  PropertyDeclaration := Format('property %s: %s read _Get%s', [EscapedDelphiName, DelphiTypeName, DelphiName]);

  if FHardcodedValue = '' then begin
    FData.ReadWriteMethodDeclarations.AddLine(
        Format('procedure _Set%s(%s: %s);', [DelphiName, EscapedDelphiName, DelphiTypeName])
    );

    FData.MethodImplementations.Add(
        (TCodeBlock.Create)
            .AddLine(
                Format(
                    'procedure %s._Set%s(%s: %s);',
                    [FData.ClassTypeName, DelphiName, EscapedDelphiName, DelphiTypeName]
                ))
            .AddLine('begin')
            .Indent
            .AddLine(Format('F%s := %s;', [DelphiName, EscapedDelphiName]))
            .Unindent
            .AddLine('end;')
    );

    PropertyDeclaration := Format('%s write _Set%s', [PropertyDeclaration, DelphiName]);
  end;

  PropertyDeclaration := PropertyDeclaration + ';';

  FData.Properties.Add(GetAccessorPasDoc).AddLine(PropertyDeclaration);
end;

procedure TFieldCodeGenerator.GenerateSerialize;
var
  ForLoopFinalValue: string;
begin
  GenerateSerializeNullOptionalGuard;
  GenerateSerializeLengthCheck;

  if FArrayField then begin
    FData.AddSerializeVar('I', 'Cardinal');

    ForLoopFinalValue := GetSerializeLengthExpression;
    if ForLoopFinalValue = '' then begin
      ForLoopFinalValue := Format('Length(F%s)', [GetDelphiFieldName]);
    end;

    if IsInteger(ForLoopFinalValue) then begin
      ForLoopFinalValue := IntToStr(StrToInt(ForLoopFinalValue) - 1);
    end
    else begin
      ForLoopFinalValue := ForLoopFinalValue + ' - 1';
    end;

    FData.Serialize.AddLine(Format('for I := 0 to %s do begin', [ForLoopFinalValue])).Indent;
    if FDelimited and not FTrailingDelimiter then begin
      (FData.Serialize) //
          .AddLine('if I > 0 then begin')
          .Indent
          .AddLine('Writer.AddByte($FF);')
          .Unindent
          .AddLine('end;');
    end;
  end;

  FData.Serialize.AddLine(GetWriteStatement);

  if FArrayField then begin
    if FDelimited and FTrailingDelimiter then begin
      FData.Serialize.AddLine('Writer.AddByte($FF)');
    end;
    FData.Serialize.Unindent.AddLine('end;');
  end;

  if FOptional then begin
    FData.Serialize.Unindent.AddLine('end;');
  end;
end;

procedure TFieldCodeGenerator.GenerateDeserialize;
begin
  if FOptional then begin
    FData.Deserialize.AddLine('if Reader.Remaining > 0 then begin').Indent;
  end;

  if FArrayField then begin
    GenerateDeserializeArray;
  end
  else begin
    FData.Deserialize.AddLine(GetReadStatement);
  end;

  if FOptional then begin
    FData.Deserialize.Unindent.AddLine('end;');
  end;
end;

{ TFieldCodeGenerator.TBuilder }

constructor TFieldCodeGenerator.TBuilder.Create(
    TypeFactory: TTypeFactory;
    Context: TObjectGenerationContext;
    Data: TObjectGenerationData
);
begin
  FTypeFactory := TypeFactory;
  FContext := Context;
  FData := Data;
  FName := '';
  FType := '';
  FLength := '';
  FOffset := 0;
  FPadded := False;
  FOptional := False;
  FHardcodedValue := '';
  FComment := '';
  FArrayField := False;
  FLengthField := False;
  FLengthFieldBackReference := '';
  FDelimited := False;
  FTrailingDelimiter := False;
end;

function TFieldCodeGenerator.TBuilder.Name(Name: string): TBuilder;
begin
  FName := Name;
  Result := Self;
end;

function TFieldCodeGenerator.TBuilder.Type_(Type_: string): TBuilder;
begin
  FType := Type_;
  Result := Self;
end;

function TFieldCodeGenerator.TBuilder.Length(Length: string): TBuilder;
begin
  FLength := Length;
  Result := Self;
end;

function TFieldCodeGenerator.TBuilder.Offset(Offset: Integer): TBuilder;
begin
  FOffset := Offset;
  Result := Self;
end;

function TFieldCodeGenerator.TBuilder.Padded(Padded: Boolean): TBuilder;
begin
  FPadded := Padded;
  Result := Self;
end;

function TFieldCodeGenerator.TBuilder.Optional(Optional: Boolean): TBuilder;
begin
  FOptional := Optional;
  Result := Self;
end;

function TFieldCodeGenerator.TBuilder.HardcodedValue(HardcodedValue: string): TBuilder;
begin
  FHardcodedValue := HardcodedValue;
  Result := Self;
end;

function TFieldCodeGenerator.TBuilder.Comment(Comment: string): TBuilder;
begin
  FComment := Comment;
  Result := Self;
end;

function TFieldCodeGenerator.TBuilder.ArrayField(ArrayField: Boolean): TBuilder;
begin
  FArrayField := ArrayField;
  Result := Self;
end;

function TFieldCodeGenerator.TBuilder.LengthField(LengthField: Boolean): TBuilder;
begin
  FLengthField := LengthField;
  Result := Self;
end;

function TFieldCodeGenerator.TBuilder.LengthFieldBackReference(LengthFieldBackReference: string): TBuilder;
begin
  FLengthFieldBackReference := LengthFieldBackReference;
  Result := Self;
end;

function TFieldCodeGenerator.TBuilder.Delimited(Delimited: Boolean): TBuilder;
begin
  FDelimited := Delimited;
  Result := Self;
end;

function TFieldCodeGenerator.TBuilder.TrailingDelimiter(TrailingDelimiter: Boolean): TBuilder;
begin
  FTrailingDelimiter := TrailingDelimiter;
  Result := Self;
end;

function TFieldCodeGenerator.TBuilder.Build: TFieldCodeGenerator;
begin
  Result :=
      TFieldCodeGenerator.Create(
          FTypeFactory,
          FContext,
          FData,
          FName,
          FType,
          FLength,
          FPadded,
          FOptional,
          FHardcodedValue,
          FComment,
          FArrayField,
          FDelimited,
          FTrailingDelimiter,
          FLengthField,
          FLengthFieldBackReference,
          FOffset
      );
end;

{ TSwitchCodeGenerator }

procedure TSwitchCodeGenerator.GenerateCaseDataType(ProtocolCase: TDOMElement; CaseContext: TObjectGenerationContext);
var
  ClassTypeName: string;
  InterfaceTypeName: string;
  ObjectCodeGenerator: TObjectCodeGenerator;
  CasePropertyName: string;
  PasDoc: string;
  ProtocolComment: string;
begin
  ClassTypeName := GetCaseDataClassTypeName(ProtocolCase);
  InterfaceTypeName := GetCaseDataInterfaceTypeName(ProtocolCase);

  ObjectCodeGenerator := TObjectCodeGenerator.Create(ClassTypeName, InterfaceTypeName, FTypeFactory, CaseContext);
  ObjectCodeGenerator.Data.AncestorInterfaces := [GetInterfaceTypeName];
  try
    ObjectCodeGenerator.GenerateInstructions(GetInstructions(ProtocolCase));
    CasePropertyName := EscapeKeyword(SnakeCaseToPascalCase(FFieldName));

    if GetBooleanAttribute(ProtocolCase, 'default') then begin
      PasDoc := Format('Default data associated with @code(%s.%s).', [FData.InterfaceTypeName, CasePropertyName]);
    end
    else begin
      PasDoc :=
          Format(
              'Data associated with @code(%s.%s) value @code(%s).',
              [FData.InterfaceTypeName, CasePropertyName, GetCaseValueExpression(ProtocolCase)]
          );
    end;

    ProtocolComment := GetComment(ProtocolCase);
    if ProtocolComment <> '' then begin
      PasDoc := PasDoc + CRLF + CRLF + ProtocolComment;
    end;

    ObjectCodeGenerator.Data.PasDoc := '{ ' + PasDoc + ' }' + CRLF;

    FData.AuxillaryTypes.AddRange(ObjectCodeGenerator.GetTypes);
  finally
    FreeAndNil(ObjectCodeGenerator);
  end;
end;

function TSwitchCodeGenerator.GetFieldData: TFieldData;
begin
  if not FContext.AccessibleFields.TryGetValue(FFieldName, Result) then begin
    raise ECodeGenerationError.CreateFmt('Referenced %s field is not accessible.', [FFieldName]);
  end;
end;

function TSwitchCodeGenerator.GetInterfaceTypeName: string;
begin
  Result := FData.InterfaceTypeName + SnakeCaseToPascalCase(FFieldName) + 'Data';
end;

function TSwitchCodeGenerator.GetCaseDataFieldName: string;
begin
  Result := SnakeCaseToPascalCase(FFieldName) + 'Data';
end;

function ProtocolCaseValueName(ProtocolCase: TDOMElement): string;
begin
  if GetBooleanAttribute(ProtocolCase, 'default') then begin
    Result := 'Default';
  end
  else begin
    Result := GetRequiredStringAttribute(ProtocolCase, 'value');
  end;
end;

function TSwitchCodeGenerator.GetCaseDataInterfaceTypeName(ProtocolCase: TDOMElement): string;
begin
  Result := FData.InterfaceTypeName + SnakeCaseToPascalCase(FFieldName) + 'Data' + ProtocolCaseValueName(ProtocolCase);
end;

function TSwitchCodeGenerator.GetCaseDataClassTypeName(ProtocolCase: TDOMElement): string;
begin
  Result := FData.ClassTypeName + SnakeCaseToPascalCase(FFieldName) + 'Data' + ProtocolCaseValueName(ProtocolCase);
end;

function TSwitchCodeGenerator.GetCaseValueDocsExpression(ProtocolCase: TDOMElement): string;
var
  Type_: TType;
  CaseValue: string;
  EnumValue: TNullable<TEnumType.TEnumValue>;
begin
  Type_ := GetFieldData.Type_;
  if Type_ is TEnumType then begin
    CaseValue := GetRequiredStringAttribute(ProtocolCase, 'value');
    EnumValue := (Type_ as TEnumType).FindEnumValueByName(CaseValue);
    if EnumValue.HasValue then begin
      Result := EnumValue.Value.Name;
    end
    else begin
      Result := Format('UNRECOGNIZED(%s)', [CaseValue]);
    end;
  end
  else begin
    Result := GetCaseValueExpression(ProtocolCase);
  end;
end;

function TSwitchCodeGenerator.GetCaseValueExpression(ProtocolCase: TDOMElement): string;
var
  FieldType: TType;
  CaseValue: string;
  EnumType: TEnumType;
  OrdinalValue: TNullable<Integer>;
  EnumValue: TNullable<TEnumType.TEnumValue>;
begin
  FieldType := GetFieldData.Type_;
  CaseValue := GetRequiredStringAttribute(ProtocolCase, 'value');

  if FieldType is TIntegerType then begin
    if not IsInteger(CaseValue) then begin
      raise ECodeGenerationError.CreateFmt('"%s" is not a valid integer value.', [CaseValue]);
    end;
    Result := CaseValue;
  end
  else if FieldType is TEnumType then begin
    EnumType := FieldType as TEnumType;
    OrdinalValue := TryParseInt(CaseValue);
    if OrdinalValue.HasValue then begin
      EnumValue := EnumType.FindEnumValueByOrdinal(OrdinalValue.Value);
      if EnumValue.HasValue then begin
        raise ECodeGenerationError.CreateFmt(
            '%s value %s must be referred to by name (%s)',
            [EnumType.Name, CaseValue, EnumValue.Value.Name]);
      end;
      Result := CaseValue;
    end
    else begin
      EnumValue := EnumType.FindEnumValueByName(CaseValue);
      if EnumValue.HasValue then begin
        Result := IntToStr(EnumValue.Value.OrdinalValue);
      end
      else begin
        raise ECodeGenerationError.CreateFmt('"%s" is not a valid value for enum type %s', [CaseValue, EnumType.Name]);
      end;
    end;
  end
  else begin
    raise ECodeGenerationError
        .CreateFmt('%s field referenced by switch must be a numeric or enumeration type.', [FFieldName]);
  end;
end;

constructor TSwitchCodeGenerator.Create(
    FieldName: string;
    TypeFactory: TTypeFactory;
    Context: TObjectGenerationContext;
    Data: TObjectGenerationData
);
begin
  FFieldName := FieldName;
  FTypeFactory := TypeFactory;
  FContext := Context;
  FData := Data;
end;

procedure TSwitchCodeGenerator.GenerateCaseDataInterface;
var
  CaseDataProperty: string;
  Guid: TGUID;
  Slice: TPascalUnitSlice;
begin
  CaseDataProperty := EscapeKeyword(SnakeCaseToPascalCase(FFieldName));
  Guid := CreateInterfaceGuid(FContext.UnitName + '.' + GetInterfaceTypeName, []);
  Slice := TPascalUnitSlice.Create;

  Slice.TypeDeclarations.Add(
      (TCodeBlock.Create)
          .AddLine(Format('{ Data associated with different values of the @code(%s) field. }', [CaseDataProperty]))
          .AddLine(Format('%s = interface(IInterface)', [GetInterfaceTypeName]))
          .Indent
          .AddLine(Format('[''%s'']', [Guid.ToString]))
          .AddLine('{ Serializes this @classname object to the provided @link(TEoWriter).')
          .AddLine('  @param(Writer The writer that this object will be serialized to) }')
          .AddLine('procedure Serialize(Writer: TEoWriter);')
          .Unindent
          .AddLine('end;')
          .AddUses('EOLib.Data')
  );

  FData.AuxillaryTypes.Add(Slice);
end;

procedure TSwitchCodeGenerator.GenerateCaseDataField;
var
  InterfaceTypeName: string;
  CaseDataFieldName: string;
  SwitchFieldName: string;
begin
  InterfaceTypeName := GetInterfaceTypeName;
  CaseDataFieldName := GetCaseDataFieldName;
  SwitchFieldName := SnakeCaseToPascalCase(GetFieldData.Name);

  FData.Fields.AddLine(Format('F%s: %s;', [CaseDataFieldName, InterfaceTypeName]));

  (FData.MethodDeclarations)
      .AddLine(Format('function _Get%s: %s;', [CaseDataFieldName, InterfaceTypeName]))
      .AddLine(Format('procedure _Set%0:s(%0:s: %1:s);', [CaseDataFieldName, InterfaceTypeName]));

  FData.MethodImplementations.Add(
      (TCodeBlock.Create)
          .AddLine(Format('function %s._Get%s: %s;', [FData.ClassTypeName, CaseDataFieldName, InterfaceTypeName]))
          .AddLine('begin')
          .Indent
          .AddLine(Format('Result := F%s;', [CaseDataFieldName]))
          .Unindent
          .AddLine('end;')
  );

  FData.MethodImplementations.Add(
      (TCodeBlock.Create)
          .AddLine(
              Format(
                  'procedure %0:s._Set%1:s(%1:s: %2:s);',
                  [FData.ClassTypeName, CaseDataFieldName, InterfaceTypeName]
              ))
          .AddLine('begin')
          .Indent
          .AddLine(Format('F%0:s := %0:s;', [CaseDataFieldName]))
          .Unindent
          .AddLine('end;')
  );

  (FData.Properties)
      .AddLine(Format('{ Data associated with the @code(%s) field. }', [SwitchFieldName]))
      .AddLine(Format('property %0:s: %1:s read _Get%0:s write _Set%0:s;', [CaseDataFieldName, InterfaceTypeName]));
end;

procedure TSwitchCodeGenerator.GenerateSwitchStart;
var
  FieldData: TFieldData;
  SwitchValueExpression: string;
begin
  FieldData := GetFieldData;
  SwitchValueExpression := 'F' + SnakeCaseToPascalCase(FieldData.Name);
  if FieldData.Type_ is TEnumType then begin
    SwitchValueExpression := SwitchValueExpression + '.ToInt';
  end;
  FData.Serialize.AddLine(Format('case %s of', [SwitchValueExpression])).Indent;
  FData.Deserialize.AddLine(Format('case Result.%s of', [SwitchValueExpression])).Indent;
end;

procedure TSwitchCodeGenerator.GenerateSwitchEnd;
begin
  FData.Serialize.Unindent.AddLine('end;');
  FData.Deserialize.Unindent.AddLine('end;');
end;

function TSwitchCodeGenerator.GenerateCase(ProtocolCase: TDOMElement; Start: Boolean): TObjectGenerationContext;
var
  CaseStart: string;
  CaseFieldName: string;
  CaseDataTypeName: string;
  CaseDataFieldName: string;
  FieldValueExpression: string;
  SerializationErrorMessage: string;
begin
  if GetBooleanAttribute(ProtocolCase, 'default') then begin
    if Start then begin
      raise ECodeGenerationError.Create('Standalone default case is not allowed.');
    end;
    CaseStart := 'else begin';
  end
  else begin
    CaseStart :=
        Format('%s {%s}: begin', [GetCaseValueExpression(ProtocolCase), GetCaseValueDocsExpression(ProtocolCase)]);
  end;

  FData.Serialize.AddLine(CaseStart).Indent;
  FData.Deserialize.AddLine(CaseStart).Indent;

  Result := TObjectGenerationContext.Create(FContext);
  Result.AccessibleFields.Clear;
  Result.LengthFieldReferencedMap.Clear;

  CaseFieldName := EscapeKeyword(SnakeCaseToPascalCase(FFieldName));
  CaseDataTypeName := GetCaseDataInterfaceTypeName(ProtocolCase);
  CaseDataFieldName := GetCaseDataFieldName;

  FieldValueExpression := 'F' + SnakeCaseToPascalCase(FFieldName);
  if GetFieldData.Type_ is TIntegerType then begin
    FieldValueExpression := Format('IntToStr(%s)', [FieldValueExpression]);
  end
  else begin
    FieldValueExpression := FieldValueExpression + '.ToString';
  end;

  if Length(GetInstructions(ProtocolCase)) = 0 then begin
    SerializationErrorMessage :=
        Format(
            '''Expected %s to be nil for %s '' + %s + '', but was instance of '' + (F%s as TObject).ClassName + ''.''',
            [CaseDataFieldName, CaseFieldName, FieldValueExpression, CaseDataFieldName]
        );

    (FData.Serialize)
        .AddLine(Format('if Assigned(F%s) then begin', [CaseDataFieldName]))
        .Indent
        .AddLine(Format('raise ESerializationError.Create(%s);', [SerializationErrorMessage]))
        .Unindent
        .AddLine('end;')
        .AddUses('EOLib.Protocol.Errors');

    FData.Deserialize.AddLine(Format('Result.F%s := nil;', [CaseDataFieldName]));
  end
  else begin
    FData.AddSerializeVar('ErrorMessage', 'string');

    GenerateCaseDataType(ProtocolCase, Result);

    SerializationErrorMessage :=
        Format(
            '''Expected %s to be instance of %s for %s '' + %s + '', but was ''',
            [CaseDataFieldName, CaseDataTypeName, CaseFieldName, FieldValueExpression]
        );

    (FData.Serialize)
        .AddLine(Format('if not Supports(F%s, %s) then begin', [CaseDataFieldName, CaseDataTypeName]))
        .Indent
        .AddLine(Format('ErrorMessage := %s;', [SerializationErrorMessage]))
        .AddLine(Format('if Assigned(F%s) then begin', [CaseDataFieldName]))
        .Indent
        .AddLine(
            Format(
                'ErrorMessage := ErrorMessage + ''instance of '' + (F%s as TObject).ClassName + ''.'';',
                [CaseDataFieldName]
            ))
        .Unindent
        .AddLine('end')
        .AddLine('else begin')
        .Indent
        .AddLine('ErrorMessage := ErrorMessage + ''nil.'';')
        .Unindent
        .AddLine('end;')
        .AddLine('raise ESerializationError.Create(ErrorMessage);')
        .Unindent
        .AddLine('end;')
        .AddLine(Format('F%s.Serialize(Writer);', [CaseDataFieldName]))
        .AddUses('{$IFDEF FPC}SysUtils{$ELSE}System.SysUtils{$ENDIF}')
        .AddUses('EOLib.Protocol.Errors');

    FData.Deserialize.AddLine(
        Format('Result.F%s := %s.Deserialize(Reader);', [CaseDatafieldName, GetCaseDataClassTypeName(ProtocolCase)])
    );
  end;

  FData.Serialize.Unindent.AddLine('end;');
  FData.Deserialize.Unindent.AddLine('end;');
end;

{ TObjectCodeGenerator }

constructor TObjectCodeGenerator.Create(
    ClassTypeName: string;
    InterfaceTypeName: string;
    TypeFactory: TTypeFactory;
    Context: TObjectGenerationContext
);
begin
  if not Assigned(Context) then begin
    Context := TObjectGenerationContext.Create;
    FOwnsContext := True;
  end;
  FClassTypeName := ClassTypeName;
  FInterfaceTypeName := InterfaceTypeName;
  FTypeFactory := TypeFactory;
  FContext := Context;
  FData := TObjectGenerationData.Create(ClassTypeName, InterfaceTypeName);
end;

destructor TObjectCodeGenerator.Destroy;
begin
  FreeAndNil(FData);
  if FOwnsContext then begin
    FreeAndNil(FContext);
  end;
end;

procedure TObjectCodeGenerator.GenerateField(Instruction: TDOMElement);
var
  Optional: Boolean;
  FieldCodeGenerator: TFieldCodeGenerator;
begin
  Optional := GetBooleanAttribute(Instruction, 'optional');
  CheckOptionalField(Optional);

  FieldCodeGenerator :=
      FieldCodeGeneratorBuilder
          .Name(GetStringAttribute(Instruction, 'name'))
          .Type_(GetRequiredStringAttribute(Instruction, 'type'))
          .Length(GetStringAttribute(Instruction, 'length'))
          .Padded(GetBooleanAttribute(Instruction, 'padded'))
          .Optional(Optional)
          .HardcodedValue(GetText(Instruction))
          .Comment(GetComment(Instruction))
          .Build;

  try
    FieldCodeGenerator.GenerateField;
    FieldCodeGenerator.GenerateSerialize;
    FieldCodeGenerator.GenerateDeserialize;
  finally
    FreeAndNil(FieldCodeGenerator);
  end;

  if Optional then begin
    FContext.ReachedOptionalField := True;
  end;
end;

procedure TObjectCodeGenerator.GenerateArray(Instruction: TDOMElement);
var
  Optional: Boolean;
  Delimited: Boolean;
  FieldCodeGenerator: TFieldCodeGenerator;
begin
  Optional := GetBooleanAttribute(Instruction, 'optional');
  CheckOptionalField(Optional);

  Delimited := GetBooleanAttribute(Instruction, 'delimited');
  if Delimited and not FContext.ChunkedReadingEnabled then begin
    raise ECodeGenerationError.Create(
        'Cannot generate a delimited array instruction unless chunked reading is enabled.');
  end;

  FieldCodeGenerator :=
      FieldCodeGeneratorBuilder
          .Name(GetRequiredStringAttribute(Instruction, 'name'))
          .Type_(GetRequiredStringAttribute(Instruction, 'type'))
          .Length(GetStringAttribute(Instruction, 'length'))
          .Optional(Optional)
          .Comment(GetComment(Instruction))
          .ArrayField(True)
          .Delimited(Delimited)
          .TrailingDelimiter(GetBooleanAttribute(Instruction, 'trailing-delimiter', True))
          .Build;

  try
    FieldCodeGenerator.GenerateField;
    FieldCodeGenerator.GenerateSerialize;
    FieldCodeGenerator.GenerateDeserialize;
  finally
    FreeAndNil(FieldCodeGenerator);
  end;

  if Optional then begin
    FContext.ReachedOptionalField := True;
  end;
end;

procedure TObjectCodeGenerator.GenerateLength(
    Instruction: TDOMElement;
    LengthFieldBackReferences: TDictionary<string, string>
);
var
  Name: string;
  Optional: Boolean;
  FieldCodeGenerator: TFieldCodeGenerator;
begin
  Name := GetRequiredStringAttribute(Instruction, 'name');
  Optional := GetBooleanAttribute(Instruction, 'optional');
  CheckOptionalField(Optional);

  FieldCodeGenerator :=
      FieldCodeGeneratorBuilder
          .Name(Name)
          .Type_(GetRequiredStringAttribute(Instruction, 'type'))
          .Offset(GetIntAttribute(Instruction, 'offset'))
          .LengthField(True)
          .LengthFieldBackReference(LengthFieldBackReferences[Name])
          .Optional(Optional)
          .Comment(GetComment(Instruction))
          .Build;

  try
    FieldCodeGenerator.GenerateField;
    FieldCodeGenerator.GenerateSerialize;
    FieldCodeGenerator.GenerateDeserialize;
  finally
    FreeAndNil(FieldCodeGenerator);
  end;

  if Optional then begin
    FContext.ReachedOptionalField := True;
  end;
end;

procedure TObjectCodeGenerator.GenerateDummy(Instruction: TDOMElement);
var
  FieldCodeGenerator: TFieldCodeGenerator;
  NeedsIfGuards: Boolean;
begin
  FieldCodeGenerator :=
      FieldCodeGeneratorBuilder
          .Type_(GetRequiredStringAttribute(Instruction, 'type'))
          .HardcodedValue(GetText(Instruction))
          .Comment(GetComment(Instruction))
          .Build;

  NeedsIfGuards := not Data.Serialize.Empty or not Data.Deserialize.Empty;

  if NeedsIfGuards then begin
    FData.Serialize.AddLine('if Writer.Length = OldWriterLength then begin').Indent;
    FData.Deserialize.AddLine('if Reader.Position = ReaderStartPosition then begin').Indent;
  end;

  try
    FieldCodeGenerator.GenerateSerialize;
    FieldCodeGenerator.GenerateDeserialize;
  finally
    FreeAndNil(FieldCodeGenerator);
  end;

  if NeedsIfGuards then begin
    FData.Serialize.Unindent.AddLine('end;');
    FData.Deserialize.Unindent.AddLine('end;');
  end;

  FContext.ReachedDummy := True;

  if NeedsIfGuards then begin
    FData.AddSerializeVar('OldWriterLength', 'Cardinal', 'OldWriterLength := Writer.Length;');
  end;
end;

procedure TObjectCodeGenerator.GenerateSwitch(Instruction: TDOMElement);
var
  SwitchCodeGenerator: TSwitchCodeGenerator;
  ProtocolCases: TArray<TDOMelement>;
  ProtocolCase: TDOMElement;
  ReachedOptionalField: Boolean;
  ReachedDummy: Boolean;
  Start: Boolean;
  CaseContext: TObjectGenerationContext;
begin
  SwitchCodeGenerator :=
      TSwitchCodeGenerator.Create( //
          GetRequiredStringAttribute(Instruction, 'field'),
          FTypeFactory,
          FContext,
          FData
      );

  ProtocolCases := GetElementsByTagName(Instruction, 'case');

  SwitchCodeGenerator.GenerateCaseDataInterface;
  SwitchCodeGenerator.GenerateCaseDataField;
  SwitchCodeGenerator.GenerateSwitchStart;

  ReachedOptionalField := FContext.ReachedOptionalField;
  ReachedDummy := FContext.ReachedDummy;
  Start := True;

  for ProtocolCase in ProtocolCases do begin
    CaseContext := SwitchCodeGenerator.GenerateCase(ProtocolCase, Start);

    ReachedOptionalField := ReachedOptionalField or CaseContext.ReachedOptionalField;
    ReachedDummy := ReachedDummy or CaseContext.ReachedDummy;
    Start := False;
  end;

  FContext.ReachedOptionalField := ReachedOptionalField;
  FContext.ReachedDummy := ReachedDummy;

  SwitchCodeGenerator.GenerateSwitchEnd;
end;

procedure TObjectCodeGenerator.GenerateChunked(
    Instruction: TDOMElement;
    LengthFieldBackReferences: TDictionary<string, string>
);
var
  WasAlreadyEnabled: Boolean;
  ChunkedInstruction: TDOMElement;
begin
  WasAlreadyEnabled := FContext.ChunkedReadingEnabled;

  if not WasAlreadyEnabled then begin
    FContext.ChunkedReadingEnabled := True;
    FData.Deserialize.AddLine('Reader.ChunkedReadingMode := True;');
  end;

  for ChunkedInstruction in GetInstructions(Instruction) do begin
    GenerateInstruction(ChunkedInstruction, LengthFieldBackReferences);
  end;

  if not WasAlreadyEnabled then begin
    FContext.ChunkedReadingEnabled := False;
    FData.Deserialize.AddLine('Reader.ChunkedReadingMode := False;');
  end;
end;

procedure TObjectCodeGenerator.GenerateBreak;
begin
  if not FContext.ChunkedReadingEnabled then begin
    raise ECodeGenerationError.Create('Cannot generate a break instruction unless chunked reading is enabled.');
  end;

  FContext.ReachedOptionalField := False;
  FContext.ReachedDummy := False;

  FData.Serialize.AddLine('Writer.AddByte($FF);');
  FData.Deserialize.AddLine('Reader.NextChunk;');
end;

procedure TObjectCodeGenerator.GenerateInstruction(
    Instruction: TDOMElement;
    LengthFieldBackReferences: TDictionary<string, string>
);
var
  Tag: string;
begin
  if FContext.ReachedDummy then begin
    raise ECodeGenerationError.Create('<dummy> elements must not be followed by any other elements.');
  end;

  Tag := Instruction.TagName;

  if SameStr(Tag, 'field') then begin
    GenerateField(Instruction);
  end
  else if SameStr(Tag, 'array') then begin
    GenerateArray(Instruction);
  end
  else if SameStr(Tag, 'length') then begin
    GenerateLength(Instruction, LengthFieldBackReferences);
  end
  else if SameStr(Tag, 'dummy') then begin
    GenerateDummy(Instruction);
  end
  else if SameStr(Tag, 'switch') then begin
    GenerateSwitch(Instruction);
  end
  else if SameStr(Tag, 'chunked') then begin
    GenerateChunked(Instruction, LengthFieldBackReferences);
  end
  else if SameStr(Tag, 'break') then begin
    GenerateBreak;
  end;
end;

procedure IndexLengthFieldBackReferences(Instructions: TArray<TDOMElement>; Result: TDictionary<string, string>);
var
  Instruction: TDOMElement;
  LengthString: string;
begin
  for Instruction in Instructions do begin
    if SameStr(Instruction.TagName, 'field') or SameStr(Instruction.TagName, 'array') then begin
      LengthString := GetStringAttribute(Instruction, 'length');
      if (LengthString <> '') and not IsInteger(LengthString) then begin
        Result.Add(LengthString, GetRequiredStringAttribute(Instruction, 'name'));
      end;
    end
    else if SameStr(Instruction.TagName, 'chunked') then begin
      IndexLengthFieldBackReferences(GetInstructions(Instruction), Result);
    end;
  end
end;

procedure TObjectCodeGenerator.GenerateInstructions(Instructions: TArray<TDOMElement>);
var
  LengthFieldBackReferences: TDictionary<string, string>;
  Instruction: TDOMElement;
begin
  LengthFieldBackReferences := TDictionary<string, string>.Create;
  try
    IndexLengthFieldBackReferences(Instructions, LengthFieldBackReferences);
    for Instruction in Instructions do begin
      GenerateInstruction(Instruction, LengthFieldBackReferences);
    end;
  finally
    FreeAndNil(LengthFieldBackReferences);
  end;
end;

function TObjectCodeGenerator.FieldCodeGeneratorBuilder: TFieldCodeGenerator.TBuilder;
begin
  Result := TFieldCodeGenerator.TBuilder.Create(FTypeFactory, FContext, FData);
end;

procedure TObjectCodeGenerator.CheckOptionalField(Optional: Boolean);
begin
  if FContext.ReachedOptionalField and not Optional then begin
    raise ECodeGenerationError.Create('Optional fields may not be followed by non-optional fields.');
  end;
end;

function TObjectCodeGenerator.GetTypes: TArray<TPascalUnitSlice>;
  function VarDeclarations(Vars: TArray<TVarData>): string;
  var
    VarData: TVarData;
  begin
    Result := '';
    for VarData in Vars do begin
      Result := Result + Format('  %s: %s;', [VarData.Name, VarData.Type_]) + CRLF;
    end;
    if Result <> '' then begin
      Result := 'var' + CRLF + Result;
    end;
  end;

  function VarInitializations(Vars: TArray<TVarData>): string;
  var
    VarData: TVarData;
  begin
    Result := '';
    for VarData in Vars do begin
      if VarData.InitializationStatement <> '' then begin
        Result := Result + VarData.InitializationStatement + CRLF;
      end;
    end;
  end;

  function GetAuxillaryTypes: TArray<TPascalUnitSlice>;
  var
    AuxillaryTypes: TList<TPascalUnitSlice>;
    AuxillaryType: TPascalUnitSlice;
  begin
    AuxillaryTypes := TList<TPascalUnitSlice>.Create;
    try
      for AuxillaryType in FData.AuxillaryTypes do begin
        AuxillaryTypes.Add(TPascalUnitSlice.Create(AuxillaryType));
      end;
      Result := AuxillaryTypes.ToArray;
    finally
      FreeAndNil(AuxillaryTypes);
    end;
  end;
var
  ConstructorDeclaration: string;
  ConstructorImplementation: TCodeBlock;
  MethodDeclarations: TCodeBlock;
  Properties: TCodeBlock;
  Guid: TGUID;
  InterfaceAncestorList: string;
  ClassAncestorList: string;
  InterfaceSlice: TPascalUnitSlice;
  ClassSlice: TPascalUnitSlice;
  Block: TCodeBlock;
begin
  ConstructorImplementation := TCodeBlock.Create;

  if not FData.Constructor_.Empty then begin
    ConstructorDeclaration := 'constructor Create;' + CRLF;
    ConstructorImplementation
        .AddLine(Format('constructor %s.Create;', [FData.ClassTypeName]))
        .AddLine('begin')
        .Indent
        .AddCodeBlock(FData.Constructor_)
        .Unindent
        .AddLine('end;')
        .AddLine;
  end;

  MethodDeclarations :=
      (TCodeBlock.Create)
          .AddLine('function _GetByteSize: Cardinal;')
          .AddCodeBlock(FData.ReadWriteMethodDeclarations)
          .AddLine
          .AddCodeBlock(FData.MethodDeclarations);

  Properties :=
      (TCodeBlock.Create)
          .AddLine('{ The size of the data that this object was deserialized from.')
          .AddLine('  @note(0 if the instance was not created by the @code(Deserialize) method.) }')
          .AddLine('property ByteSize: Cardinal read _GetByteSize;')
          .AddCodeBlock(FData.Properties);

  Guid := CreateInterfaceGuid(FData.UnitName + '.' + FData.InterfaceTypeName, FData.FieldSignatures.ToArray);

  InterfaceAncestorList := '';
  if Length(FData.AncestorInterfaces) > 0 then begin
    InterfaceAncestorList := Format('(%s)', [Join(FData.AncestorInterfaces, ', ')]);
  end;

  ClassAncestorList :=
      Format('(%s)', [Join(Concat(['TInterfacedObject'], FData.AncestorInterfaces, [FData.InterfaceTypeName]), ', ')]);

  InterfaceSlice := TPascalUnitSlice.Create;
  ClassSlice := TPascalUnitSlice.Create;

  InterfaceSlice.TypeDeclarations.Add(
      (TCodeBlock.Create)
          .Add(FData.PasDoc)
          .AddLine(Format('%s = interface%s', [FData.InterfaceTypeName, InterfaceAncestorList]))
          .Indent
          .AddLine(Format('[''%s'']', [Guid.ToString]))
          .AddCodeBlock(MethodDeclarations)
          .AddLine('{ Serializes this @classname object to the provided @link(TEoWriter).')
          .AddLine('  @param(Writer The writer that this object will be serialized to) }')
          .AddLine('procedure Serialize(Writer: TEoWriter);')
          .AddLine
          .AddCodeBlock(Properties)
          .Unindent
          .AddLine('end;')
          .AddUses('EOLib.Data')
  );

  ClassSlice.TypeDeclarations.Add(
      (TCodeBlock.Create)
          .Add(FData.PasDoc)
          .AddLine(Format('%s = class%s', [FData.ClassTypeName, ClassAncestorList]))
          .AddLine('strict private')
          .Indent
          .AddLine('FByteSize: Cardinal;')
          .AddCodeBlock(FData.Fields)
          .Unindent
          .AddLine('public')
          .Indent
          .Add(ConstructorDeclaration)
          .AddCodeBlock(MethodDeclarations)
          .AddLine('{ Serializes this @classname object to the provided @link(TEoWriter).')
          .AddLine('  @param(Writer The writer that this object will be serialized to) }')
          .AddLine('procedure Serialize(Writer: TEoWriter);')
          .AddLine
          .AddCodeBlock(FData.ClassMethodDeclarations)
          .AddLine('{ Deserializes an instance of @classname from the provided @link(TEoReader).')
          .AddLine('  @param(Reader The reader that the object will be deserialized from)')
          .AddLine('  @returns(The deserialized object) }')
          .AddLine(Format('class function Deserialize(Reader: TEoReader): %s;', [FData.ClassTypeName]))
          .AddLine
          .AddCodeBlock(Properties)
          .Unindent
          .AddLine('end;')
  );

  FreeAndNil(MethodDeclarations);
  FreeAndNil(Properties);

  (ClassSlice.ImplementationBlock)
      .AddLine(Format('{ %s }', [FData.ClassTypeName]))
      .AddLine
      .AddCodeBlock(ConstructorImplementation)
      .AddLine(Format('function %s._GetByteSize: Cardinal;', [FData.ClassTypeName]))
      .AddLine('begin')
      .Indent
      .AddLine('Result := FByteSize;')
      .Unindent
      .AddLine('end;')
      .AddLine;

  FreeAndNil(ConstructorImplementation);

  for Block in FData.MethodImplementations do begin
    ClassSlice.ImplementationBlock.AddCodeBlock(Block).AddLine;
  end;

  (ClassSlice.ImplementationBlock)
      .AddLine(Format('procedure %s.Serialize(Writer: TEoWriter);', [FData.ClassTypeName]))
      .Add(VarDeclarations(FData.SerializeVars))
      .AddLine('begin')
      .Indent
      .AddLine('OldStringSanitizationMode := Writer.StringSanitizationMode;')
      .Add(VarInitializations(FData.SerializeVars))
      .AddLine('try')
      .Indent
      .AddCodeBlock(FData.Serialize)
      .Unindent
      .AddLine('finally')
      .Indent
      .AddLine('Writer.StringSanitizationMode := OldStringSanitizationMode;')
      .Unindent
      .AddLine('end;')
      .Unindent
      .AddLine('end;')
      .AddLine
      .AddLine(Format('class function %0:s.Deserialize(Reader: TEoReader): %0:s;', [FData.ClassTypeName]))
      .Add(VarDeclarations(FData.DeserializeVars))
      .AddLine('begin')
      .Indent
      .AddLine('OldChunkedReadingMode := Reader.ChunkedReadingMode;')
      .Add(VarInitializations(FData.DeserializeVars))
      .AddLine(Format('Result := %s.Create;', [FData.ClassTypeName]))
      .AddLine('try')
      .Indent
      .AddLine('try')
      .Indent
      .AddLine('ReaderStartPosition := Reader.Position;')
      .AddCodeBlock(FData.Deserialize)
      .AddLine('Result.FByteSize := Reader.Position - ReaderStartPosition;')
      .Unindent
      .AddLine('except')
      .Indent
      .AddLine('Result.Free;')
      .AddLine('raise;')
      .Unindent
      .AddLine('end;')
      .Unindent
      .AddLine('finally')
      .Indent
      .AddLine('Reader.ChunkedReadingMode := OldChunkedReadingMode;')
      .Unindent
      .AddLine('end;')
      .Unindent
      .AddLine('end;');

  Result := GetAuxillaryTypes + [InterfaceSlice, ClassSlice];
end;

end.
