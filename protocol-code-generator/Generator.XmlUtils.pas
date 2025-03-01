unit Generator.XmlUtils;

{$MODE DELPHIUNICODE}
{$H+}

interface

uses
  SysUtils,
  DOM,
  Generics.Collections;

type
  EXmlError = class(Exception);

function GetElementsByTagName(Document: TDOMDocument; TagName: string): TArray<TDOMElement>; overload;
function GetElementsByTagName(Element: TDOMElement; TagName: string): TArray<TDOMElement>; overload;

function GetInstructions(Element: TDOMElement): TArray<TDOMElement>;
function GetComment(Element: TDOMElement): string;
function GetText(Element: TDOMElement): string;

function GetStringAttribute(Element: TDOMElement; Name: string; DefaultValue: string = ''): string;
function GetIntAttribute(Element: TDOMElement; Name: string; DefaultValue: Integer = 0): Integer;
function GetBooleanAttribute(Element: TDOMElement; Name: string; DefaultValue: Boolean = False): Boolean;

function GetRequiredStringAttribute(Element: TDOMElement; Name: string): string;
function GetRequiredIntAttribute(Element: TDOMElement; Name: string): Integer;
function GetRequiredBooleanAttribute(Element: TDOMElement; Name: string): Boolean;

implementation

function NodeListToArray(NodeList: TDOMNodeList): TArray<TDOMElement>;
var
  I: Integer;
begin
  Result := Default(TArray<TDOMElement>);
  SetLength(Result, NodeList.Count);
  for I := 0 to NodeList.Count - 1 do begin
    Result[I] := NodeList[I] as TDOMElement;
  end;
  FreeAndNil(NodeList);
end;

function GetElementsByTagName(Children: TDOMNodeList; TagName: string): TArray<TDOMElement>;
var
  I: Integer;
  Elements: TList<TDOMElement>;
  Child: TDOMNode;
begin
  Elements := TList<TDOMElement>.Create;
  try
    for I := 0 to Children.Count - 1 do begin
      Child := Children[I];
      if Child is TDOMElement and SameStr((Child as TDOMElement).TagName, TagName) then begin
        Elements.Add(Child as TDOMElement);
      end;
    end;
    Result := Elements.ToArray;
  finally
    FreeAndNil(Elements);
  end;
end;

function GetElementsByTagName(Document: TDOMDocument; TagName: string): TArray<TDOMElement>;
begin
  Result := GetElementsByTagName(Document.ChildNodes, TagName);
end;

function GetElementsByTagName(Element: TDOMElement; TagName: string): TArray<TDOMElement>;
begin
  Result := GetElementsByTagName(Element.ChildNodes, TagName);
end;

function GetInstructions(Element: TDOMElement): TArray<TDOMElement>;
var
  Instructions: TList<TDOMElement>;
  Child: TDOMNode;
begin
  Instructions := TList<TDOMElement>.Create;
  Child := Element.FirstChild;
  while Assigned(Child) do begin
    if (Child.NodeType = ELEMENT_NODE) and (Child.NodeName = 'field')
        or (Child.NodeName = 'array')
        or (Child.NodeName = 'length')
        or (Child.NodeName = 'dummy')
        or (Child.NodeName = 'switch')
        or (Child.NodeName = 'chunked')
        or (Child.NodeName = 'break') then
    begin
      Instructions.Add(Child as TDomElement);
    end;
    Child := Child.NextSibling;
  end;
  Result := Instructions.ToArray;
  FreeAndNil(Instructions);
end;

function GetComment(Element: TDOMElement): string;
var
  Child: TDOMNode;
begin
  Result := '';
  Child := Element.FirstChild;
  while Assigned(Child) do begin
    if (Child.NodeType = ELEMENT_NODE) and (Child.NodeName = 'comment') then begin
      Result := GetText(Child as TDOMElement);
      Exit;
    end;
    Child := Child.NextSibling;
  end;
end;

function GetText(Element: TDOMElement): string;
var
  Child: TDOMNode;
  TextContent: string;
begin
  Result := '';
  Child := Element.FirstChild;
  while Assigned(Child) do begin
    if Child.NodeType = TEXT_NODE then begin
      TextContent := Trim(TDOMText(child).Data);
      if Result <> '' then begin
        raise EXmlError.CreateFmt('Unexpected text content "%s"', [TextContent]);
      end;
      Result := TextContent;
    end;
    Child := Child.NextSibling;
  end;
end;

function GetStringAttribute(Element: TDOMElement; Name: string; DefaultValue: string = ''): string;
begin
  if Element.HasAttribute(Name) then begin
    Result := Element.GetAttribute(Name)
  end
  else begin
    Result := DefaultValue;
  end;
end;

function GetIntAttribute(Element: TDOMElement; Name: string; DefaultValue: Integer = 0): Integer;
var
  Value: string;
begin
  Value := GetStringAttribute(Element, Name);
  if Value = '' then begin
    Result := DefaultValue
  end
  else begin
    try
      Result := StrToInt(Value);
    except
      on E: EConvertError do begin
        raise EXmlError.CreateFmt('%s attribute has an invalid integer value: %s', [Name, Value]);
      end;
    end;
  end;
end;

function GetBooleanAttribute(Element: TDOMElement; Name: string; DefaultValue: Boolean = False): Boolean;
var
  Value: string;
begin
  Value := GetStringAttribute(Element, Name);
  if Value = '' then begin
    Result := DefaultValue
  end
  else begin
    Result := LowerCase(Value) = 'true';
  end;
end;

function GetRequiredStringAttribute(Element: TDOMElement; Name: string): string;
begin
  if Element.HasAttribute(Name) then begin
    Result := Element.GetAttribute(Name)
  end
  else begin
    raise EXmlError.CreateFmt('Required attribute "%s" is missing.', [Name]);
  end;
end;

function GetRequiredIntAttribute(Element: TDOMElement; Name: string): Integer;
var
  Value: string;
begin
  Value := GetRequiredStringAttribute(Element, Name);
  try
    Result := StrToInt(Value);
  except
    on E: EConvertError do begin
      raise EXmlError.CreateFmt('%s attribute has an invalid integer value: %s', [Name, Value]);
    end;
  end;
end;

function GetRequiredBooleanAttribute(Element: TDOMElement; Name: string): Boolean;
var
  Value: string;
begin
  Value := GetRequiredStringAttribute(Element, Name);
  Result := LowerCase(Value) = 'true';
end;

end.
