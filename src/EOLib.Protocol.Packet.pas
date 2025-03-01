{ EO network protocol data structures. }
unit EOLib.Protocol.Packet;

{$IFDEF FPC}
  {$MODE DELPHIUNICODE}
  {$H+}
  {$WARNINGS OFF}
{$ENDIF}

interface

uses
  EOLib.Data,
  EOLib.Protocol.Net;

type
  { Object representation of a packet in the EO network protocol. }
  IPacket = interface(IInterface)
    ['{63804096-9E2D-4263-AB94-33E41C30988E}']
    { Returns the packet family associated with this packet.
      @returns(The packet family associated with this packet) }
    function Family: TPacketFamily;

    { Returns the packet action associated with this packet.
      @returns(The packet action associated with this packet) }
    function Action: TPacketAction;

    { Serializes this @classname object to the provided @link(TEoWriter).
      @param(Writer The writer that this object will be serialized to) }
    procedure Serialize(Writer: TEoWriter);
  end;

implementation

end.
