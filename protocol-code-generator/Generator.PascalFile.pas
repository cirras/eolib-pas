unit Generator.PascalFile;

{$MODE DELPHIUNICODE}
{$H+}

interface

uses
  Classes,
  Generics.Collections;

type
  TCodeBlock = class(TObject)
  strict private
    FLines: TList<string>;
    FIndentation: Integer;
    function IsEmpty: Boolean;
    function GetAsString: string;
  private
    FUses: TStringList;
  public
    constructor Create; overload;
    constructor Create(Other: TCodeBlock); overload;
    destructor Destroy; override;
    function Add(Code: string): TCodeBlock;
    function AddLine(Line: string = ''): TCodeBlock;
    function AddCodeBlock(Block: TCodeBlock): TCodeBlock;
    function AddUses(UnitName: string): TCodeBlock;
    function Indent: TCodeBlock;
    function Unindent: TCodeBlock;
    property Empty: Boolean read IsEmpty;
    property AsString: string read GetAsString;
  end;

  TPascalUnitSlice = class(TObject)
  strict private
    FTypeDeclarations: TList<TCodeBlock>;
    FImplementationBlock: TCodeBlock;
  public
    constructor Create; overload;
    constructor Create(Other: TPascalUnitSlice); overload;
    destructor Destroy; override;
    property TypeDeclarations: TList<TCodeBlock> read FTypeDeclarations;
    property ImplementationBlock: TCodeBlock read FImplementationBlock;
  end;

  TPascalUnit = class(TObject)
  strict private
    FUnitName: string;
    FSlices: TList<TPascalUnitSlice>;
  public
    constructor Create(UnitName: string);
    destructor Destroy; override;
    function Add(Slice: TPascalUnitSlice): TPascalUnit;
    procedure Write(OutputDirectory: string);
    property UnitName: string read FUnitName;
  end;

implementation

uses
  SysUtils,
  StrUtils,
  Generator.StringUtils;

{ TCodeBlock }

constructor TCodeBlock.Create;
begin
  FUses := TStringList.Create;
  FUses.Sorted := True;
  FUses.Duplicates := dupIgnore;

  FLines := TList<string>.Create;
  FLines.Add('');
end;

constructor TCodeBlock.Create(Other: TCodeBlock);
begin
  FUses := TStringList.Create;
  FUses.Sorted := True;
  FUses.Duplicates := dupIgnore;
  FUses.AddStrings(Other.FUses);

  FLines := TList<string>.Create;
  FLines.AddRange(Other.FLines);

  FIndentation := Other.FIndentation;
end;

destructor TCodeBlock.Destroy;
begin
  FreeAndNil(FUses);
end;

function TCodeBlock.IsEmpty: Boolean;
begin
  Result := (FLines.Count = 1) and (Length(FLines[0]) = 0);
end;

function TCodeBlock.GetAsString: string;
begin
  Result := Join(FLines.ToArray, CRLF);
end;

function TCodeBlock.Add(Code: string): TCodeBlock;
var
  Lines: TArray<string>;
  I: Integer;
  LineIndex: Integer;
begin
  Lines := Split(Code, [CRLF, LF]);

  for I := 0 to Length(Lines) - 1 do begin
    if Length(Lines[I]) > 0 then begin
      LineIndex := FLines.Count - 1;
      if FLines[LineIndex] = '' then begin
        FLines[LineIndex] := DupeString(' ', FIndentation * 2);
      end;
      FLines[LineIndex] := FLines[LineIndex] + Lines[I];
    end;

    if I <> Length(Lines) - 1 then begin
      FLines.Add('');
    end;
  end;

  Result := Self;
end;

function TCodeBlock.AddLine(Line: string): TCodeBlock;
begin
  Add(Line + CRLF);
  Result := Self;
end;

function TCodeBlock.AddCodeBlock(Block: TCodeBlock): TCodeBlock;
var
  I: Integer;
begin
  for I := 0 to Block.FLines.Count - 1 do begin
    if I = Block.FLines.Count - 1 then begin
      Add(Block.FLines[I]);
    end
    else begin
      AddLine(Block.FLines[I]);
    end;
  end;
  FUses.AddStrings(Block.FUses);
  Result := Self;
end;

function TCodeBlock.AddUses(UnitName: string): TCodeBlock;
begin
  FUses.Add(UnitName);
  Result := Self;
end;

function TCodeBlock.Indent: TCodeBlock;
begin
  Inc(FIndentation);
  Result := Self;
end;

function TCodeBlock.Unindent: TCodeBlock;
begin
  Dec(FIndentation);
  Result := Self;
end;

{ TPascalUnitSlice }

constructor TPascalUnitSlice.Create;
begin
  FTypeDeclarations := TObjectList<TCodeBlock>.Create;
  FImplementationBlock := TCodeBlock.Create;
end;

constructor TPascalUnitSlice.Create(Other: TPascalUnitSlice);
var
  TypeDeclaration: TCodeBlock;
begin
  FTypeDeclarations := TObjectList<TCodeBlock>.Create;
  for TypeDeclaration in Other.FTypeDeclarations do begin
    FTypeDeclarations.Add(TCodeBlock.Create(TypeDeclaration));
  end;
  FImplementationBlock := TCodeBlock.Create(Other.FImplementationBlock);
end;

destructor TPascalUnitSlice.Destroy;
begin
  FreeAndNil(FTypeDeclarations);
  FreeAndNil(FImplementationBlock);
end;

{ TPascalUnit }

constructor TPascalUnit.Create(UnitName: string);
begin
  FUnitName := UnitName;
  FSlices := TObjectList<TPascalUnitSlice>.Create;
end;

destructor TPascalUnit.Destroy;
begin
  FreeAndNil(FSlices);
end;

function TPascalUnit.Add(Slice: TPascalUnitSlice): TPascalUnit;
begin
  FSlices.Add(Slice);
  Result := Self;
end;

procedure TPascalUnit.Write(OutputDirectory: string);
  function FileHeaderSection: string;
  begin
    Result :=
        ('// Generated from the eo-protocol XML specification.' + CRLF)
            + ('//' + CRLF)
            + ('// This file should not be modified.' + CRLF)
            + ('// Changes will be lost when code is regenerated.' + CRLF)
            + CRLF
            + ('unit ' + FUnitName + ';' + CRLF)
            + CRLF
            + ('{$IFDEF FPC}' + CRLF)
            + ('  {$MODE DELPHIUNICODE}{$H+}' + CRLF)
            + ('  {$WARNINGS OFF}' + CRLF)
            + ('{$ENDIF}' + CRLF)
            + CRLF
            + ('{$SCOPEDENUMS ON}' + CRLF)
            + ('{$MINENUMSIZE 4}' + CRLF)
            + CRLF;
  end;

  function InterfaceSection: string;
  var
    UsesClause: string;
    CombinedUses: TStringList;
    Slice: TPascalUnitSlice;
    Block: TCodeBlock;
    TypeSection: TCodeBlock;
    Used: string;
  begin
    UsesClause := '';
    CombinedUses := TStringList.Create;
    CombinedUses.Sorted := True;
    CombinedUses.Duplicates := dupIgnore;

    try
      for Slice in FSlices do begin
        for Block in Slice.TypeDeclarations do begin
          CombinedUses.AddStrings(Block.FUses);
        end;
        CombinedUses.AddStrings(Slice.ImplementationBlock.FUses);
      end;
      for Used in CombinedUses do begin
        if SameStr(Used, FUnitName) then begin
          Continue;
        end;
        if UsesClause = '' then begin
          UsesClause := 'uses' + CRLF;
        end
        else begin
          UsesClause := UsesClause + ',' + CRLF;
        end;
        UsesClause := UsesClause + '  ' + Used;
      end;
      if UsesClause <> '' then begin
        UsesClause := UsesClause + ';' + CRLF;
      end;
    finally
      FreeAndNil(CombinedUses);
    end;

    Result := 'interface' + CRLF + CRLF + UsesClause + CRLF;

    TypeSection := TCodeBlock.Create;
    try
      TypeSection.AddLine('type').Indent;
      for Slice in FSlices do begin
        for Block in Slice.TypeDeclarations do begin
          TypeSection.AddCodeBlock(Block).AddLine;
        end;
      end;
      Result := Result + TypeSection.AsString;
    finally
      FreeAndNil(TypeSection);
    end;
  end;

  function ImplementationSection: string;
  var
    Slice: TPascalUnitSlice;
    BlockString: string;
  begin
    Result := 'implementation' + CRLF + CRLF;
    for Slice in FSlices do begin
      BlockString := Slice.ImplementationBlock.AsString;
      if BlockString <> '' then begin
        BlockString := BlockString + CRLF;
      end;
      Result := Result + BlockString;
    end;
  end;

var
  Content: string;
  ContentBytes: TBytes;
  PreambleBytes: TBytes;
  FileName: string;
  FileStream: TFileStream;
begin
  Content := FileHeaderSection + InterfaceSection + ImplementationSection + 'end.' + CRLF;
  ContentBytes := TEncoding.UTF8.GetBytes(Content);
  PreambleBytes := TEncoding.UTF8.GetPreamble;

  FileName := OutputDirectory + '/' + FUnitName + '.pas';
  FileStream := TFileStream.Create(FileName, fmCreate);

  try
    FileStream.WriteBuffer(PreambleBytes[0], Length(PreambleBytes));
    FileStream.WriteBuffer(ContentBytes[0], Length(ContentBytes));
  finally
    FreeAndNil(FileStream);
  end;
end;

end.
