{ Utilities to handle EO data encryption. }
unit EOLib.Encrypt;

{$IFDEF FPC}
  {$MODE DELPHIUNICODE}{$H+}
  {$WARNINGS OFF}
{$ENDIF}

interface

{ Interleaves a sequence of bytes. When encrypting EO data, bytes are "woven" into each other.
  @br
  Used when encrypting packets and data files.

  Example:

  @longCode(#
    [0, 1, 2, 3, 4, 5] → [0, 5, 1, 4, 2, 3]
  #)

  This is an in-place operation.

  @param(Data The data to interleave) }
procedure Interleave(var Data: TArray<Byte>);

{ Deinterleaves a sequence of bytes. This is the reverse of @link(Interleave). @br
  Used when decrypting packets and data files.

  Example:

  @longCode(#
    [0, 1, 2, 3, 4, 5] → [0, 2, 4, 5, 3, 1]
  #)

  This is an in-place operation.

  @param(Data The data to deinterleave) }
procedure Deinterleave(var Data: TArray<Byte>);

{ Flips the most significant bits of each byte in a sequence of bytes. (Values @code(0) and
  @code(128) are not flipped.) @br
  Used when encrypting and decrypting packets.

  Example:

  @longCode(#
    [0, 1, 127, 128, 129, 254, 255] → [0, 129, 255, 128, 1, 126, 127]
  #)

  This is an in-place operation.

  @param(Data The data to flip most significant bits on) }
procedure FlipMsb(var Data: TArray<Byte>);

{ Swaps the order of contiguous bytes in a sequence of bytes that are divisible by a given multiple
  value. @br
  Used when encrypting and decrypting packets and data files.

  Example:

  @longCode(#
    Multiple := 3
    [10, 21, 27] → [10, 27, 21]
  #)

  This is an in-place operation.

  @param(Data The data to swap bytes in)
  @param(Multiple The multiple value) }
procedure SwapMultiples(var Data: TArray<Byte>; Multiple: Cardinal);

{ This hash function is how the game client checks that it's communicating with a genuine server
  during connection initialization.

  @unorderedList(
    @item(The client sends an integer value to the server in the INIT_INIT client packet, where it
      is referred to as the @code(Challenge).)
    @item(The server hashes the value and sends the hash back in the INIT_INIT server packet.)
    @item(The client hashes the value and compares it to the hash sent by the server.)
    @item(If the hashes don't match, the client drops the connection.)
  )

  @warning(Oversized challenges may result in negative hash values, which cannot be represented
    properly in the EO protocol.)

  @param(Challenge The challenge value sent by the client. Should be no larger than
    @code(11,092,110))

  @returns(The hashed challenge value) }
function ServerVerificationHash(Challenge: Cardinal): Integer;

implementation

procedure Interleave(var Data: TArray<Byte>);
var
  Buffer: TArray<Byte>;
  I: Integer;
  J: Integer;
begin
  if Length(Data) = 0 then begin
    Exit;
  end;

  SetLength(Buffer{%H-}, Length(Data));

  I := 0;
  J := 0;

  while I < Length(Data) do begin
    Buffer[I] := Data[J];
    Inc(I, 2);
    Inc(J);
  end;

  Dec(I);

  if Length(Data) mod 2 <> 0 then begin
    Dec(I, 2);
  end;

  while I >= 0 do begin
    Buffer[I] := Data[J];
    Dec(I, 2);
    Inc(J);
  end;

  System.Move(Buffer[0], Data[0], Length(Data));
end;

procedure Deinterleave(var Data: TArray<Byte>);
var
  Buffer: TArray<Byte>;
  I: Integer;
  J: Integer;
begin
  if Length(Data) = 0 then begin
    Exit
  end;

  SetLength(Buffer{%H-}, Length(Data));

  I := 0;
  J := 0;

  while I < Length(Data) do begin
    Buffer[J] := Data[I];
    Inc(I, 2);
    Inc(J);
  end;

  Dec(I);

  if Length(Data) mod 2 <> 0 then begin
    Dec(I, 2);
  end;

  while I >= 0 do begin
    Buffer[J] := Data[I];
    Dec(I, 2);
    Inc(J);
  end;

  System.Move(Buffer[0], Data[0], Length(Data));
end;

procedure FlipMsb(var Data: TArray<Byte>);
var
  I: Integer;
begin
  for I := 0 to High(Data) do begin
    if (Data[I] and $7F) <> 0 then begin
      Data[I] := Data[I] xor $80;
    end;
  end;
end;

procedure SwapMultiples(var Data: TArray<Byte>; Multiple: Cardinal);
var
  SequenceLength: Integer;
  I: Integer;
  J: Integer;
  B: Byte;
begin
  if Multiple = 0 then begin
    Exit;
  end;

  SequenceLength := 0;

  for I := 0 to Length(Data) do begin
    if (I <> Length(Data)) and (Byte(Data[I]) mod Multiple = 0) then begin
      Inc(SequenceLength);
    end
    else begin
      if SequenceLength > 1 then begin
        for J := 0 to (SequenceLength div 2) - 1 do begin
          B := Data[I - SequenceLength + J];
          Data[I - SequenceLength + J] := Data[I - J - 1];
          Data[I - J - 1] := B;
        end;
      end;

      SequenceLength := 0;
    end;
  end;
end;

function ServerVerificationHash(Challenge: Cardinal): Integer;
begin
  Inc(Challenge);
  Result := 110905 +
    (Challenge mod 9 + 1) * ((Int64(11092004) - Challenge) mod ((Challenge mod 11 + 1) * 119)) * 119 +
    Challenge mod 2004;
end;

end.

