{ EO protocol exception types. }
unit EOLib.Protocol.Errors;

{$IFDEF FPC}
  {$MODE DELPHIUNICODE}{$H+}
  {$WARNINGS OFF}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  SysUtils;
{$ELSE}
  System.SysUtils;
{$ENDIF}


type
  { @name is raised when an error occurs during the serialization of a protocol data structure. }
  ESerializationError = class(Exception);

implementation

end.
