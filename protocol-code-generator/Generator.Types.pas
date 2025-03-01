unit Generator.Types;

{$MODE DELPHIUNICODE}
{$H+}

interface

uses
  SysUtils,
  Classes,
  Generics.Collections,
  Generics.Defaults,
  nullable,
  DOM;

type
  {$REGION Miscellaneous}

  ETypeError = class(Exception)
  end;

  TUnresolvedCustomType = class(TObject)
  strict private
    FTypeXml: TDOMElement;
    FUnitName: string;
  public
    constructor Create(TypeXml: TDOMElement; UnitName: string);
    property TypeXml: TDOMElement read FTypeXml write FTypeXml;
    property UnitName: string read FUnitName write FUnitName;
  end;

  TLength = record
  strict private
    FInput: TNullable<string>;
    FValue: TNullable<Integer>;
  strict private
    function IsSpecified: Boolean;
  public
    class function FromString(Input: string): TLength; static;
    class function Unspecified: TLength; static;
    function ToString: string;
    property AsInteger: TNullable<Integer> read FValue;
    property Specified: Boolean read IsSpecified;
  end;

  {$ENDREGION}

  {$REGION Types}

  TType = class abstract(TSingletonImplementation)
  strict protected
    function GetName: string; virtual; abstract;
    function GetFixedSize: TNullable<Integer>; virtual; abstract;
    function IsBounded: Boolean; virtual; abstract;
  public
    property Name: string read GetName;
    property FixedSize: TNullable<Integer> read GetFixedSize;
    property Bounded: Boolean read IsBounded;
  end;

  TBasicType = class abstract(TType);

  TIntegerType = class(TBasicType)
  strict private
    FName: string;
    FSize: Integer;
  strict protected
    function GetName: string; override;
    function GetFixedSize: TNullable<Integer>; override;
    function IsBounded: Boolean; override;
  public
    constructor Create(Name: string; Size: Integer);
  end;

  TStringType = class(TBasicType)
  strict private
    FName: string;
    FLength: TLength;
  strict protected
    function GetName: string; override;
    function GetFixedSize: TNullable<Integer>; override;
    function IsBounded: Boolean; override;
  public
    constructor Create(Name: string; Length: TLength);
  end;

  TBlobType = class(TType)
  strict protected
    function GetName: string; override;
    function GetFixedSize: TNullable<Integer>; override;
    function IsBounded: Boolean; override;
  end;

  IHasUnderlyingType = interface
    ['{72EB1590-1DFF-4251-9425-286707806F25}']
    function UnderlyingType: TIntegerType;
  end;

  TBoolType = class(TBasicType, IHasUnderlyingType)
  strict private
    FUnderlyingType: TIntegerType;
  strict protected
    function GetName: string; override;
    function GetFixedSize: TNullable<Integer>; override;
    function IsBounded: Boolean; override;
  public
    constructor Create(UnderlyingType: TIntegerType);
    function UnderlyingType: TIntegerType;
  end;

  TCustomType = class abstract(TType)
  strict protected
    function GetUnitName: string; virtual; abstract;
  public
    property UnitName: string read GetUnitName;
  end;

  TEnumType = class(TCustomType, IHasUnderlyingType)
  public
    type
      TEnumValue = record
      strict private
        FOrdinalValue: Integer;
        FName: string;
      public
        constructor Create(OrdinalValue: Integer; Name: string);
        property OrdinalValue: Integer read FOrdinalValue;
        property Name: string read FName;
      end;
  strict private
    FName: string;
    FUnitName: string;
    FUnderlyingType: TIntegerType;
    FValues: TArray<TEnumType.TEnumValue>;
  strict protected
    function GetName: string; override;
    function GetUnitName: string; override;
    function GetFixedSize: TNullable<Integer>; override;
    function IsBounded: Boolean; override;
  public
    constructor Create(
        Name: string;
        UnitName: string;
        UnderlyingType: TIntegerType;
        Values: TArray<TEnumType.TEnumValue>
    );
    function UnderlyingType: TIntegerType;
    function FindEnumValueByOrdinal(OrdinalValue: Integer): TNullable<TEnumType.TEnumValue>;
    function FindEnumValueByName(Name: string): TNullable<TEnumType.TEnumValue>;
    property Values: TArray<TEnumType.TEnumValue> read FValues;
  end;

  TStructType = class(TCustomType)
  strict private
    FName: string;
    FFixedSize: TNullable<Integer>;
    FBounded: Boolean;
    FUnitName: string;
  strict protected
    function GetName: string; override;
    function GetUnitName: string; override;
    function GetFixedSize: TNullable<Integer>; override;
    function IsBounded: Boolean; override;
  public
    constructor Create(Name: string; FixedSize: TNullable<Integer>; Bounded: Boolean; UnitName: string);
  end;

  {$ENDREGION}

  TTypeFactory = class(TObject)
  strict private
    FUnresolvedTypes: TObjectDictionary<string, TUnresolvedCustomType>;
    FTypes: TObjectDictionary<string, TType>;
    function CreateType(Name: string; Length: TLength): TType;
    function ReadUnderlyingType(Name: string): TIntegerType;
    function CreateCustomType(Name: string; UnderlyingTypeOverride: TIntegerType): TType;
    function CreateEnumType(TypeXml: TDOMElement; UnderlyingTypeOverride: TIntegerType; UnitName: string): TType;
    function CreateStructType(TypeXml: TDOMElement; UnitName: string): TType;
    function CalculateFixedStructSize(TypeXml: TDOMElement): TNullable<Integer>;
    function IsBounded(StructXml: TDOMElement): Boolean;
    class function CreateTypeLengthForField(FieldXml: TDOMElement): TLength;
    class function CreateTypeWithSpecifiedLength(Name: string; Length: TLength): TType;
  public
    constructor Create;
    destructor Destroy; override;
    function DefineCustomType(TypeXml: TDOMElement; UnitName: string): Boolean;
    function GetType(Name: string): TType; overload;
    function GetType(Name: string; Length: TLength): TType; overload;
    procedure Clear;
  end;

implementation

uses
  Types,
  StrUtils,
  Generator.NumberUtils,
  Generator.XmlUtils;

{$REGION Miscellaneous}

{ TUnresolvedCustomType }

constructor TUnresolvedCustomType.Create(TypeXml: TDOMElement; UnitName: string);
begin
  FTypeXml := TypeXml;
  FUnitName := UnitName;
end;

{ TLength }

class function TLength.FromString(Input: string): TLength;
begin
  Result.FInput := Input;
  Result.FValue := TryParseInt(Input);
end;

class function TLength.Unspecified: TLength;
begin
  Result.FInput := TNullable<string>.Empty;
  Result.FValue := TNullable<Integer>.Empty;
end;

function TLength.ToString: string;
begin
  if FInput.HasValue then begin
    Result := FInput.Value;
  end
  else begin
    Result := '[unspecified]';
  end;
end;

function TLength.IsSpecified: Boolean;
begin
  Result := FInput.HasValue;
end;

{$ENDREGION}

{$REGION Types}

{ TIntegerType }

function TIntegerType.GetName: string;
begin
  Result := FName;
end;

function TIntegerType.GetFixedSize: TNullable<Integer>;
begin
  Result := FSize;
end;

function TIntegerType.IsBounded: Boolean;
begin
  Result := True;
end;

constructor TIntegerType.Create(Name: string; Size: Integer);
begin
  FName := Name;
  FSize := Size;
end;

{ TStringType }

function TStringType.GetName: string;
begin
  Result := FName;
end;

function TStringType.GetFixedSize: TNullable<Integer>;
begin
  Result := FLength.AsInteger;
end;

function TStringType.IsBounded: Boolean;
begin
  Result := FLength.Specified;
end;

constructor TStringType.Create(Name: string; Length: TLength);
begin
  FName := Name;
  FLength := Length;
end;

{ TBoolType }

function TBoolType.GetName: string;
begin
  Result := 'bool';
end;

function TBoolType.GetFixedSize: TNullable<Integer>;
begin
  Result := FUnderlyingType.FixedSize;
end;

function TBoolType.IsBounded: Boolean;
begin
  Result := FUnderlyingType.Bounded;
end;

constructor TBoolType.Create(UnderlyingType: TIntegerType);
begin
  FUnderlyingType := UnderlyingType;
end;

function TBoolType.UnderlyingType: TIntegerType;
begin
  Result := FUnderlyingType;
end;

{ TBlobType }

function TBlobType.GetName: string;
begin
  Result := 'blob';
end;

function TBlobType.GetFixedSize: TNullable<Integer>;
begin
  Result := TNullable<Integer>.Empty;
end;

function TBlobType.IsBounded: Boolean;
begin
  Result := False;
end;

{ TEnumType }

constructor TEnumType.TEnumValue.Create(OrdinalValue: Integer; Name: string);
begin
  FOrdinalValue := OrdinalValue;
  FName := Name;
end;

function TEnumType.GetName: string;
begin
  Result := FName;
end;

function TEnumType.GetUnitName: string;
begin
  Result := FUnitName;
end;

function TEnumType.GetFixedSize: TNullable<Integer>;
begin
  Result := FUnderlyingType.FixedSize;
end;

function TEnumType.IsBounded: Boolean;
begin
  Result := FUnderlyingType.Bounded;
end;

constructor TEnumType.Create(
    Name: string;
    UnitName: string;
    UnderlyingType: TIntegerType;
    Values: TArray<TEnumType.TEnumValue>
);
begin
  FName := Name;
  FUnitName := UnitName;
  FUnderlyingType := UnderlyingType;
  FValues := Values;
end;

function TEnumType.UnderlyingType: TIntegerType;
begin
  Result := FUnderlyingType;
end;

function TEnumType.FindEnumValueByOrdinal(OrdinalValue: Integer): TNullable<TEnumType.TEnumValue>;
var
  Value: TEnumType.TEnumValue;
begin
  Result := TNullable<TEnumType.TEnumValue>.Empty;
  for Value in FValues do begin
    if Value.OrdinalValue = OrdinalValue then begin
      Result := Value;
      Break;
    end;
  end;
end;

function TEnumType.FindEnumValueByName(Name: string): TNullable<TEnumType.TEnumValue>;
var
  Value: TEnumType.TEnumValue;
begin
  Result := TNullable<TEnumType.TEnumValue>.Empty;
  for Value in FValues do begin
    if SameStr(Value.Name, Name) then begin
      Result := Value;
      Break;
    end;
  end;
end;

{ TStructType }

function TStructType.GetName: string;
begin
  Result := FName;
end;

function TStructType.GetUnitName: string;
begin
  Result := FUnitName;
end;

function TStructType.GetFixedSize: TNullable<Integer>;
begin
  Result := FFixedSize;
end;

function TStructType.IsBounded: Boolean;
begin
  Result := FBounded;
end;

constructor TStructType.Create(Name: string; FixedSize: TNullable<Integer>; Bounded: Boolean; UnitName: string);
begin
  FName := Name;
  FFixedSize := FixedSize;
  FBounded := Bounded;
  FUnitName := UnitName;
end;

{$ENDREGION}

{ TTypeFactory }

constructor TTypeFactory.Create;
begin
  FUnresolvedTypes := TObjectDictionary<string, TUnresolvedCustomType>.Create([doOwnsValues]);
  FTypes := TObjectDictionary<string, TType>.Create([doOwnsValues]);
end;

destructor TTypeFactory.Destroy;
begin
  FreeAndNil(FUnresolvedTypes);
  FreeAndNil(FTypes);
end;

function TTypeFactory.DefineCustomType(TypeXml: TDOMElement; UnitName: string): Boolean;
var
  Name: string;
  UnresolvedType: TUnresolvedCustomType;
begin
  Name := GetRequiredStringAttribute(TypeXml, 'name');
  UnresolvedType := TUnresolvedCustomType.Create(TypeXml, UnitName);
  Result := FUnresolvedTypes.TryAdd(Name, UnresolvedType);
  if not Result then begin
    FreeAndNil(UnresolvedType);
  end;
end;

function TTypeFactory.GetType(Name: string): TType;
begin
  Result := GetType(Name, TLength.Unspecified);
end;

function TTypeFactory.GetType(Name: string; Length: TLength): TType;
begin
  if Length.Specified then begin
    Result := CreateTypeWithSpecifiedLength(Name, Length);
    Exit;
  end;
  if not FTypes.ContainsKey(Name) then begin
    FTypes.Add(Name, CreateType(Name, Length));
  end;
  Result := FTypes[Name];
end;

function TTypeFactory.CreateType(Name: string; Length: TLength): TType;
var
  UnderlyingType: TIntegerType;
begin
  UnderlyingType := ReadUnderlyingType(Name);
  if Assigned(UnderlyingType) then begin
    Name := LeftStr(Name, Pos(':', Name) - 1);
  end;

  if SameStr(Name, 'byte') or SameStr(Name, 'char') then begin
    Result := TIntegerType.Create(Name, 1);
  end
  else if SameStr(Name, 'short') then begin
    Result := TIntegerType.Create(Name, 2);
  end
  else if SameStr(Name, 'three') then begin
    Result := TIntegerType.Create(Name, 3);
  end
  else if SameStr(Name, 'int') then begin
    Result := TIntegerType.Create(Name, 4);
  end
  else if SameStr(Name, 'bool') then begin
    if not Assigned(UnderlyingType) then begin
      UnderlyingType := GetType('char') as TIntegerType;
    end;
    Result := TBoolType.Create(UnderlyingType);
  end
  else if SameStr(Name, 'string') or SameStr(Name, 'encoded_string') then begin
    Result := TStringType.Create(Name, Length);
  end
  else if SameStr(Name, 'blob') then begin
    Result := TBlobType.Create;
  end
  else begin
    Result := CreateCustomType(Name, UnderlyingType);
  end;

  if Assigned(UnderlyingType) and not (Result is IHasUnderlyingType) then begin
    FreeAndNil(Result);
    raise ETypeError.CreateFmt(
        '%s has no underlying type, so %s is not allowed as an underlying type override.',
        [Name, UnderlyingType.Name]);
  end;
end;

function TTypeFactory.ReadUnderlyingType(Name: string): TIntegerType;
var
  NameParts: TStringDynArray;
  TypeName: string;
  UnderlyingTypeName: string;
  UnderlyingType: TType;
begin
  NameParts := SplitString(Name, ':');

  case Length(NameParts) of
    1:
      Result := nil;
    2: begin
      TypeName := NameParts[0];
      UnderlyingTypeName := NameParts[1];

      if TypeName = UnderlyingTypeName then begin
        raise ETypeError.CreateFmt('%s type cannot specify itself as an underlying type.', [TypeName]);
      end;

      UnderlyingType := GetType(UnderlyingTypeName);
      if not (UnderlyingType is TIntegerType) then begin
        raise ETypeError.CreateFmt(
            '%s is not a numeric type, so it cannot be specified as an underlying type.',
            [UnderlyingType.Name]);
      end;

      Result := UnderlyingType as TIntegerType;
    end;
  else
    raise ETypeError.CreateFmt('"%s" type syntax is invalid. (Only one colon is allowed)', [Name]);
  end;
end;

function TTypeFactory.CreateCustomType(Name: string; UnderlyingTypeOverride: TIntegerType): TType;
var
  UnresolvedType: TUnresolvedCustomType;
  Tag: string;
begin
  UnresolvedType := FUnresolvedTypes[Name];
  if not Assigned(UnresolvedType) then begin
    raise ETypeError.CreateFmt('%s type is not defined.', [Name]);
  end;

  Tag := UnresolvedType.TypeXml.TagName;

  if SameStr(Tag, 'enum') then begin
    Result := CreateEnumType(UnresolvedType.TypeXml, UnderlyingTypeOverride, UnresolvedType.UnitName);
  end
  else if SameStr(Tag, 'struct') then begin
    Result := CreateStructType(UnresolvedType.TypeXml, UnresolvedType.UnitName);
  end
  else begin
    raise EAssertionFailed.CreateFmt('Unhandled CustomType xml element: <%s>', [Tag]);
  end;
end;

function TTypeFactory.CreateEnumType(
    TypeXml: TDOMElement;
    UnderlyingTypeOverride: TIntegerType;
    UnitName: string
): TType;
var
  UnderlyingType: TIntegerType;
  DefaultUnderlyingType: TType;
  EnumName: string;
  UnderlyingTypeName: string;
  Values: TList<TEnumType.TEnumValue>;
  Ordinals: THashSet<Integer>;
  Names: THashSet<string>;
  ProtocolValue: TDOMElement;
  ValueText: string;
  ValueOrdinal: TNullable<Integer>;
  ValueName: string;
begin
  UnderlyingType := UnderlyingTypeOverride;
  EnumName := GetRequiredStringAttribute(TypeXml, 'name');

  if not Assigned(UnderlyingType) then begin
    UnderlyingTypeName := GetRequiredStringAttribute(TypeXml, 'type');
    if SameStr(EnumName, UnderlyingTypeName) then begin
      raise ETypeError.CreateFmt('%s type cannot specify itself as an underlying type.', [EnumName]);
    end;

    DefaultUnderlyingType := GetType(UnderlyingTypeName);
    if not (DefaultUnderlyingType is TIntegerType) then begin
      raise ETypeError.CreateFmt(
          '%s is not a numeric type, so it cannot be specified as an underlying type.',
          [DefaultUnderlyingType.Name]);
    end;

    UnderlyingType := DefaultUnderlyingType as TIntegerType;
  end;

  Values := TList<TEnumType.TEnumValue>.Create;
  Ordinals := THashSet<Integer>.Create;
  Names := THashSet<string>.Create;

  try
    for ProtocolValue in GetElementsByTagName(TypeXml, 'value') do begin
      ValueText := GetText(ProtocolValue);
      ValueOrdinal := TryParseInt(ValueText);
      ValueName := GetRequiredStringAttribute(ProtocolValue, 'name');

      if ValueOrdinal.IsNull then begin
        raise ETypeError.CreateFmt('%s.%s has invalid ordinal value "%s".', [EnumName, ValueName, ValueText]);
      end;

      if not Ordinals.Add(ValueOrdinal.Value) then begin
        raise ETypeError
            .CreateFmt('%s.%s cannot redefine ordinal value %d.', [EnumName, ValueName, ValueOrdinal.Value]);
      end;

      if not Names.Add(ValueName) then begin
        raise ETypeError.CreateFmt('%s enum cannot redefine valuse name %s.', [EnumName, ValueName]);
      end;

      Values.Add(TEnumType.TEnumValue.Create(ValueOrdinal, ValueName));
    end;

    Result := TEnumType.Create(EnumName, UnitName, UnderlyingType, Values.ToArray);
  finally
    FreeAndNil(Values);
    FreeAndNil(Ordinals);
    FreeAndNil(Names);
  end;
end;

function TTypeFactory.CreateStructType(TypeXml: TDOMElement; UnitName: string): TType;
begin
  Result :=
      TStructType.Create(
          GetRequiredStringAttribute(TypeXml, 'name'),
          CalculateFixedStructSize(TypeXml),
          IsBounded(TypeXml),
          UnitName
      );
end;

function FlattenInstructions(Element: TDOMElement): TArray<TDOMElement>;
  procedure FlattenInstruction(Instruction: TDOMElement; Instructions: TList<TDOMElement>);
  var
    Tag: string;
    NestedInstruction: TDOMElement;
    ProtocolCase: TDOMElement;
  begin
    Instructions.Add(Instruction);

    Tag := Instruction.TagName;

    if SameStr(Tag, 'chunked') then begin
      for NestedInstruction in GetInstructions(Instruction) do begin
        FlattenInstruction(NestedInstruction, Instructions);
      end;
    end
    else if SameStr(Tag, 'switch') then begin
      for ProtocolCase in GetElementsByTagName(Instruction, 'case') do begin
        for NestedInstruction in GetInstructions(ProtocolCase) do begin
          FlattenInstruction(NestedInstruction, Instructions);
        end;
      end;
    end;
  end;
var
  Instructions: TList<TDOMElement>;
  Instruction: TDOMElement;
begin
  Instructions := TList<TDOMElement>.Create;
  try
    for Instruction in GetInstructions(Element) do begin
      FlattenInstruction(Instruction, Instructions);
    end;
    Result := Instructions.ToArray;
  finally
    FreeAndNil(Instructions);
  end;
end;

function TTypeFactory.CalculateFixedStructSize(TypeXml: TDOMElement): TNullable<Integer>;
  function FieldSize(FieldXml: TDOMElement): TNullable<Integer>;
  var
    TypeName: string;
    TypeLength: TLength;
  begin
    if GetBooleanAttribute(FieldXml, 'optional') then begin
      // Nothing can be optional in a fixed-size struct
      Result := TNullable<Integer>.Empty;
      Exit;
    end;

    TypeName := GetRequiredStringAttribute(FieldXml, 'type');
    TypeLength := CreateTypeLengthForField(FieldXml);
    Result := GetType(TypeName, TypeLength).FixedSize;
  end;

  function ArraySize(ArrayXml: TDOMElement): TNullable<Integer>;
  var
    LengthString: string;
    Length: TNullable<Integer>;
    TypeName: string;
    TypeInstance: TType;
    ElementSize: TNullable<Integer>;
  begin
    LengthString := GetStringAttribute(ArrayXml, 'length');
    Length := TryParseInt(LengthString);

    if Length.IsNull then begin
      // An array cannot be fixed-size unless a numeric length attribute is provided
      Result := TNullable<Integer>.Empty;
      Exit;
    end;

    TypeName := GetRequiredStringAttribute(ArrayXml, 'type');
    TypeInstance := GetType(TypeName);

    ElementSize := TypeInstance.FixedSize;

    if ElementSize.IsNull then begin
      // An array cannot be fixed-size unless its elements are also fixed-size
      // All arrays in a fixed-size struct must also be fixed-size
      Result := TNullable<Integer>.Empty;
      Exit;
    end;

    if GetBooleanAttribute(ArrayXml, 'optional') then begin
      // Nothing can be optional in a fixed-size struct
      Result := TNullable<Integer>.Empty;
      Exit;
    end;

    if GetBooleanAttribute(ArrayXml, 'delimited') then begin
      // It's possible to omit data or insert garbage data at the end of each chunk
      Result := TNullable<Integer>.Empty;
      Exit;
    end;

    Result := Length.Value * ElementSize.Value;
  end;

  function DummySize(DummyXml: TDOMElement): TNullable<Integer>;
  var
    TypeName: string;
  begin
    TypeName := GetRequiredStringAttribute(DummyXml, 'type');
    Result := GetType(TypeName).FixedSize;
  end;
var
  Size: Integer;
  Instruction: TDOMElement;
  InstructionSize: TNullable<Integer>;
  Tag: string;
begin
  Size := 0;

  for Instruction in FlattenInstructions(TypeXml) do begin
    InstructionSize := 0;
    Tag := Instruction.TagName;

    if SameStr(Tag, 'field') then begin
      InstructionSize := FieldSize(Instruction);
    end
    else if SameStr(Tag, 'array') then begin
      InstructionSize := ArraySize(Instruction);
    end
    else if SameStr(Tag, 'dummy') then begin
      InstructionSize := DummySize(Instruction);
    end
    else if SameStr(Tag, 'chunked') then begin
      // Chunked reading is not allowed in fixed-size structs
      InstructionSize := TNullable<Integer>.Empty;
    end
    else if SameStr(Tag, 'switch') then begin
      // Switch sections are not allowed in fixed-sized structs
      InstructionSize := TNullable<Integer>.Empty;
    end;

    if InstructionSize.IsNull then begin
      Result := TNullable<Integer>.Empty;
      Exit;
    end;

    Size := Size + InstructionSize.Value;
  end;

  Result := Size;
end;

function TTypeFactory.IsBounded(StructXml: TDOMElement): Boolean;
var
  Instruction: TDOMElement;
  Tag: string;
  TypeInstance: TType;
begin
  Result := True;

  for Instruction in FlattenInstructions(StructXml) do begin
    if not Result then begin
      Result := not SameStr(Instruction.TagName, 'break');
      Continue;
    end;

    Tag := Instruction.TagName;

    if SameStr(Tag, 'field') then begin
      TypeInstance := GetType(GetRequiredStringAttribute(Instruction, 'type'), CreateTypeLengthForField(Instruction));
      Result := TypeInstance.Bounded;
    end
    else if SameStr(Tag, 'array') then begin
      TypeInstance := GetType(GetRequiredStringAttribute(Instruction, 'type'));
      Result := TypeInstance.Bounded and Instruction.HasAttribute('length');
    end
    else if SameStr(Tag, 'dummy') then begin
      TypeInstance := GetType(GetRequiredStringAttribute(Instruction, 'type'));
      Result := TypeInstance.Bounded;
    end;
  end;
end;

class function TTypeFactory.CreateTypeLengthForField(FieldXml: TDOMElement): TLength;
begin
  if FieldXml.HasAttribute('length') then begin
    Result := TLength.FromString(GetStringAttribute(FieldXml, 'length'));
  end
  else begin
    Result := TLength.Unspecified;
  end;
end;

class function TTypeFactory.CreateTypeWithSpecifiedLength(Name: string; Length: TLength): TType;
begin
  if SameStr(Name, 'string') or SameStr(Name, 'encoded_string') then begin
    Result := TStringType.Create(Name, Length);
  end
  else begin
    raise ETypeError.CreateFmt(
        '%s type with length %s is invalid. (Only string types may specify a length)',
        [Name, Length.ToString])
  end;
end;

procedure TTypeFactory.Clear;
begin
  FUnresolvedTypes.Clear;
  FTypes.Clear;
end;

end.
