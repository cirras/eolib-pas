program Generator;

{$MODE DELPHIUNICODE}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes,
  SysUtils,
  CustApp,
  Generator.CodeGenerator;

type
  TGeneratorApplication = class(TCustomApplication)
  private
    procedure ValidateOptions;
    function GetRequiredParameter(ShortName: Char; LongName: string): string;
    procedure WriteHelp;
    procedure GenerateCode;
  protected
    procedure DoRun; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

procedure TGeneratorApplication.ValidateOptions;
var
  ErrorMsg: String;
begin
  ErrorMsg := CheckOptions('hs:o:', ['help', 'source-directory:', 'output-directory:']);
  if ErrorMsg <> '' then begin
    raise Exception.Create(ErrorMsg);
  end;
end;

function TGeneratorApplication.GetRequiredParameter(ShortName: Char; LongName: string): string;
begin
  if not HasOption(ShortName, LongName) then begin
    raise Exception.CreateFmt('Parameter "--%s" is required.', [LongName])
  end;
  Result := GetOptionValue(ShortName, LongName);
end;

procedure TGeneratorApplication.WriteHelp;
begin
  WriteLn(Format('Usage: %s [OPTIONS]', [ExtractFileName(ExeName)]));
  WriteLn;
  WriteLn('Options:');
  WriteLn('  -h, --help                  Show this help message and exit');
  WriteLn('  -s, --source-directory=DIR  Source directory containing protocol.xml files');
  WriteLn('  -o, --output-directory=DIR  Output directory for the generated source files');
end;

procedure TGeneratorApplication.GenerateCode;
var
  Generator: TCodeGenerator;
begin
  Generator := TCodeGenerator.Create(
    GetRequiredParameter('s', 'source-directory'),
    GetRequiredParameter('o', 'output-directory')
  );

  try
    Generator.Generate;
  finally
    FreeAndNil(Generator);
  end;
end;

procedure TGeneratorApplication.DoRun;
begin
  try
    ValidateOptions;

    if HasOption('h', 'help') then begin
      WriteHelp;
    end
    else begin
      GenerateCode;
    end;

    Terminate;
  except
    on E: Exception do begin
      WriteLn('Error: ' + E.Message);
      Terminate(1);
    end;
  end;
end;

constructor TGeneratorApplication.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  StopOnException := True;
end;

var
  Application: TGeneratorApplication;
begin
  Application := TGeneratorApplication.Create(nil);
  Application.Title := 'Protocol Code Generator';
  Application.Run;

  FreeAndNil(Application);
end.

