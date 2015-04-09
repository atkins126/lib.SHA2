{-------------------------------------------------------------------------------

  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at http://mozilla.org/MPL/2.0/.

-------------------------------------------------------------------------------}
{===============================================================================

  SHA2 Hash Calculation

  ©František Milt 2015-03-19

  Version 1.0

  Following hash sizes are supported in current implementation:
    SHA-224
    SHA-256
    SHA-384
    SHA-512
    SHA-512/224
    SHA-512/256

===============================================================================}
unit SHA2;

{$DEFINE LargeBuffer}
{.$DEFINE UseStringStream}

interface

uses
  Classes;

type
{$IFDEF FPC}
  QuadWord = QWord;
{$ELSE}
{$IF CompilerVersion <= 15}
  QuadWord = Int64;
{$ELSE}
  QuadWord = UInt64;
{$IFEND}
{$ENDIF}

{$IFDEF x64}
  TSize = UInt64;
{$ELSE}
  TSize = LongWord;
{$ENDIF}

  TOctaWord = record
    case Integer of
      0:(Lo,Hi:     QuadWord);
      1:(Bytes:     Array[0..15] of Byte);
      2:(Words:     Array[0..7] of Word);
      3:(LongWords: Array[0..3] of LongWord);
      4:(QuadWords: Array[0..1] of QuadWord);
  end;
  POctaWord = ^TOctaWord;  
  OctaWord = TOctaWord;

const
  ZeroOctaWord: OctaWord = (Lo: 0; Hi: 0);

type
  TSHA2Hash_32 = record
    PartA:  LongWord;
    PartB:  LongWord;
    PartC:  LongWord;
    PartD:  LongWord;
    PartE:  LongWord;
    PartF:  LongWord;
    PartG:  LongWord;
    PartH:  LongWord;
  end;

  TSHA2Hash_224 = type TSHA2Hash_32;
  TSHA2Hash_256 = type TSHA2Hash_32;

  TSHA2Hash_64 = record
    PartA:  QuadWord;
    PartB:  QuadWord;
    PartC:  QuadWord;
    PartD:  QuadWord;
    PartE:  QuadWord;
    PartF:  QuadWord;
    PartG:  QuadWord;
    PartH:  QuadWord;
  end;

  TSHA2Hash_384 = type TSHA2Hash_64;
  TSHA2Hash_512 = type TSHA2Hash_64;

  TSHA2Hash_512_224 = type TSHA2Hash_512;
  TSHA2Hash_512_256 = type TSHA2Hash_512;

  TSHA2HashSize = (sha224, sha256, sha384, sha512, sha512_224, sha512_256);

  TSHA2Hash = record
    case HashSize: TSHA2HashSize of
      sha224:     (Hash224:     TSHA2Hash_224);
      sha256:     (Hash256:     TSHA2Hash_256);
      sha384:     (Hash384:     TSHA2Hash_384);
      sha512:     (Hash512:     TSHA2Hash_512);
      sha512_224: (Hash512_224: TSHA2Hash_512_224);
      sha512_256: (Hash512_256: TSHA2Hash_512_256);
  end;

const
  InitialSHA2_224: TSHA2Hash_224 =(
    PartA: $C1059ED8;
    PartB: $367CD507;
    PartC: $3070DD17;
    PartD: $F70E5939;
    PartE: $FFC00B31;
    PartF: $68581511;
    PartG: $64F98FA7;
    PartH: $BEFA4FA4);

  InitialSHA2_256: TSHA2Hash_256 =(
    PartA: $6A09E667;
    PartB: $BB67AE85;
    PartC: $3C6Ef372;
    PartD: $A54ff53A;
    PartE: $510E527f;
    PartF: $9B05688C;
    PartG: $1F83d9AB;
    PartH: $5BE0CD19);

  InitialSHA2_384: TSHA2Hash_384 =(
    PartA: QuadWord($CBBB9D5DC1059ED8);
    PartB: QuadWord($629A292A367CD507);
    PartC: QuadWord($9159015A3070DD17);
    PartD: QuadWord($152FECD8F70E5939);
    PartE: QuadWord($67332667FFC00B31);
    PartF: QuadWord($8EB44A8768581511);
    PartG: QuadWord($DB0C2E0D64F98FA7);
    PartH: QuadWord($47B5481DBEFA4FA4));

  InitialSHA2_512: TSHA2Hash_512 =(
    PartA: QuadWord($6A09E667F3BCC908);
    PartB: QuadWord($BB67AE8584CAA73B);
    PartC: QuadWord($3C6EF372FE94F82B);
    PartD: QuadWord($A54FF53A5F1D36F1);
    PartE: QuadWord($510E527FADE682D1);
    PartF: QuadWord($9B05688C2B3E6C1F);
    PartG: QuadWord($1F83D9ABFB41BD6B);
    PartH: QuadWord($5BE0CD19137E2179));

  InitialSHA2_512mod: TSHA2Hash_512 =(
    PartA: QuadWord($CFAC43C256196CAD);
    PartB: QuadWord($1EC20B20216F029E);
    Partc: QuadWord($99CB56D75B315D8E);
    PartD: QuadWord($00EA509FFAB89354);
    PartE: QuadWord($F4ABF7DA08432774);
    PartF: QuadWord($3EA0CD298E9BC9BA);
    PartG: QuadWord($BA267C0E5EE418CE);
    PartH: QuadWord($FE4568BCB6DB84DC));

  ZeroSHA2_224: TSHA2Hash_224 = (PartA: 0; PartB: 0; PartC: 0; PartD: 0;
                                 PartE: 0; PartF: 0; PartG: 0; PartH: 0);    
  ZeroSHA2_256: TSHA2Hash_256 = (PartA: 0; PartB: 0; PartC: 0; PartD: 0;
                                 PartE: 0; PartF: 0; PartG: 0; PartH: 0);
  ZeroSHA2_384: TSHA2Hash_384 = (PartA: 0; PartB: 0; PartC: 0; PartD: 0;
                                 PartE: 0; PartF: 0; PartG: 0; PartH: 0);
  ZeroSHA2_512: TSHA2Hash_512 = (PartA: 0; PartB: 0; PartC: 0; PartD: 0;
                                 PartE: 0; PartF: 0; PartG: 0; PartH: 0);

  ZeroSHA2_512_224: TSHA2Hash_512_224 = (PartA: 0; PartB: 0; PartC: 0; PartD: 0;
                                         PartE: 0; PartF: 0; PartG: 0; PartH: 0);
  ZeroSHA2_512_256: TSHA2Hash_512_256 = (PartA: 0; PartB: 0; PartC: 0; PartD: 0;
                                         PartE: 0; PartF: 0; PartG: 0; PartH: 0);

Function BuildOctaWord(Lo,Hi: QuadWord): OctaWord;

Function InitialSHA2_512_224: TSHA2Hash_512_224;
Function InitialSHA2_512_256: TSHA2Hash_512_256;

//------------------------------------------------------------------------------

Function SHA2ToStr(Hash: TSHA2Hash_224): String; overload;
Function SHA2ToStr(Hash: TSHA2Hash_256): String; overload;
Function SHA2ToStr(Hash: TSHA2Hash_384): String; overload;
Function SHA2ToStr(Hash: TSHA2Hash_512): String; overload;
Function SHA2ToStr(Hash: TSHA2Hash_512_224): String; overload;
Function SHA2ToStr(Hash: TSHA2Hash_512_256): String; overload;
Function SHA2ToStr(Hash: TSHA2Hash): String; overload;

Function StrToSHA2_224(Str: String): TSHA2Hash_224;
Function StrToSHA2_256(Str: String): TSHA2Hash_256;
Function StrToSHA2_384(Str: String): TSHA2Hash_384;
Function StrToSHA2_512(Str: String): TSHA2Hash_512;
Function StrToSHA2_512_224(Str: String): TSHA2Hash_512_224;
Function StrToSHA2_512_256(Str: String): TSHA2Hash_512_256;
Function StrToSHA2(HashSize: TSHA2HashSize; Str: String): TSHA2Hash;

Function TryStrToSHA2(const Str: String; out Hash: TSHA2Hash_224): Boolean; overload;
Function TryStrToSHA2(const Str: String; out Hash: TSHA2Hash_256): Boolean; overload;
Function TryStrToSHA2(const Str: String; out Hash: TSHA2Hash_384): Boolean; overload;
Function TryStrToSHA2(const Str: String; out Hash: TSHA2Hash_512): Boolean; overload;
Function TryStrToSHA2(const Str: String; out Hash: TSHA2Hash_512_224): Boolean; overload;
Function TryStrToSHA2(const Str: String; out Hash: TSHA2Hash_512_256): Boolean; overload;
Function TryStrToSHA2(HashSize: TSHA2HashSize; const Str: String; out Hash: TSHA2Hash): Boolean; overload;

Function StrToSHA2Def(const Str: String; Default: TSHA2Hash_224): TSHA2Hash_224; overload;
Function StrToSHA2Def(const Str: String; Default: TSHA2Hash_256): TSHA2Hash_256; overload;
Function StrToSHA2Def(const Str: String; Default: TSHA2Hash_384): TSHA2Hash_384; overload;
Function StrToSHA2Def(const Str: String; Default: TSHA2Hash_512): TSHA2Hash_512; overload;
Function StrToSHA2Def(const Str: String; Default: TSHA2Hash_512_224): TSHA2Hash_512_224; overload;
Function StrToSHA2Def(const Str: String; Default: TSHA2Hash_512_256): TSHA2Hash_512_256; overload;
Function StrToSHA2Def(HashSize: TSHA2HashSize; const Str: String; Default: TSHA2Hash): TSHA2Hash; overload;

Function SameSHA2(A,B: TSHA2Hash_224): Boolean; overload;
Function SameSHA2(A,B: TSHA2Hash_256): Boolean; overload;
Function SameSHA2(A,B: TSHA2Hash_384): Boolean; overload;
Function SameSHA2(A,B: TSHA2Hash_512): Boolean; overload;
Function SameSHA2(A,B: TSHA2Hash_512_224): Boolean; overload;
Function SameSHA2(A,B: TSHA2Hash_512_256): Boolean; overload;
Function SameSHA2(A,B: TSHA2Hash): Boolean; overload;

//------------------------------------------------------------------------------

procedure BufferSHA2(var Hash: TSHA2Hash_224; const Buffer; Size: TSize); overload;
procedure BufferSHA2(var Hash: TSHA2Hash_256; const Buffer; Size: TSize); overload;
procedure BufferSHA2(var Hash: TSHA2Hash_384; const Buffer; Size: TSize); overload;
procedure BufferSHA2(var Hash: TSHA2Hash_512; const Buffer; Size: TSize); overload;
procedure BufferSHA2(var Hash: TSHA2Hash_512_224; const Buffer; Size: TSize); overload;
procedure BufferSHA2(var Hash: TSHA2Hash_512_256; const Buffer; Size: TSize); overload;
procedure BufferSHA2(var Hash: TSHA2Hash; const Buffer; Size: TSize); overload;

Function LastBufferSHA2(Hash: TSHA2Hash_224; const Buffer; Size: TSize; MessageLength: QuadWord): TSHA2Hash_224; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_256; const Buffer; Size: TSize; MessageLength: QuadWord): TSHA2Hash_256; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_384; const Buffer; Size: TSize; MessageLength: OctaWord): TSHA2Hash_384; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_512; const Buffer; Size: TSize; MessageLength: OctaWord): TSHA2Hash_512; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_512_224; const Buffer; Size: TSize; MessageLength: OctaWord): TSHA2Hash_512_224; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_512_256; const Buffer; Size: TSize; MessageLength: OctaWord): TSHA2Hash_512_256; overload;

Function LastBufferSHA2(Hash: TSHA2Hash_384; const Buffer; Size: TSize; MessageLengthLo: QuadWord): TSHA2Hash_384; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_512; const Buffer; Size: TSize; MessageLengthLo: QuadWord): TSHA2Hash_512; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_512_224; const Buffer; Size: TSize; MessageLengthLo: QuadWord): TSHA2Hash_512_224; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_512_256; const Buffer; Size: TSize; MessageLengthLo: QuadWord): TSHA2Hash_512_256; overload;

Function LastBufferSHA2(Hash: TSHA2Hash_384; const Buffer; Size: TSize; MessageLengthLo, MessageLengthHi: QuadWord): TSHA2Hash_384; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_512; const Buffer; Size: TSize; MessageLengthLo, MessageLengthHi: QuadWord): TSHA2Hash_512; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_512_224; const Buffer; Size: TSize; MessageLengthLo, MessageLengthHi: QuadWord): TSHA2Hash_512_224; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_512_256; const Buffer; Size: TSize; MessageLengthLo, MessageLengthHi: QuadWord): TSHA2Hash_512_256; overload;

Function LastBufferSHA2(Hash: TSHA2Hash; const Buffer; Size: TSize; MessageLength: QuadWord): TSHA2Hash; overload;
Function LastBufferSHA2(Hash: TSHA2Hash; const Buffer; Size: TSize; MessageLengthLo, MessageLengthHi: QuadWord): TSHA2Hash; overload;
Function LastBufferSHA2(Hash: TSHA2Hash; const Buffer; Size: TSize; MessageLength: OctaWord): TSHA2Hash; overload;

Function LastBufferSHA2(Hash: TSHA2Hash_224; const Buffer; Size: TSize): TSHA2Hash_224; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_256; const Buffer; Size: TSize): TSHA2Hash_256; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_384; const Buffer; Size: TSize): TSHA2Hash_384; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_512; const Buffer; Size: TSize): TSHA2Hash_512; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_512_224; const Buffer; Size: TSize): TSHA2Hash_512_224; overload;
Function LastBufferSHA2(Hash: TSHA2Hash_512_256; const Buffer; Size: TSize): TSHA2Hash_512_256; overload;
Function LastBufferSHA2(Hash: TSHA2Hash; const Buffer; Size: TSize): TSHA2Hash; overload;

//------------------------------------------------------------------------------

Function BufferSHA2(HashSize: TSHA2HashSize; const Buffer; Size: TSize): TSHA2Hash; overload;

Function AnsiStringSHA2(HashSize: TSHA2HashSize; const Str: AnsiString): TSHA2Hash;
Function WideStringSHA2(HashSize: TSHA2HashSize; const Str: WideString): TSHA2Hash;
Function StringSHA2(HashSize: TSHA2HashSize; const Str: String): TSHA2Hash;

Function StreamSHA2(HashSize: TSHA2HashSize; Stream: TStream; Count: Int64 = -1): TSHA2Hash;
Function FileSHA2(HashSize: TSHA2HashSize; const FileName: String): TSHA2Hash;

//------------------------------------------------------------------------------

type
  TSHA2Context = type Pointer;

Function SHA2_Init(HashSize: TSHA2HashSize): TSHA2Context;
procedure SHA2_Update(Context: TSHA2Context; const Buffer; Size: TSize);
Function SHA2_Final(var Context: TSHA2Context; const Buffer; Size: TSize): TSHA2Hash; overload;
Function SHA2_Final(var Context: TSHA2Context): TSHA2Hash; overload;
Function SHA2_Hash(HashSize: TSHA2HashSize; const Buffer; Size: TSize): TSHA2Hash;

implementation

uses
  SysUtils, Math;

const
  BlockSize_32    = 64;                             // 512 bits
  BlockSize_64    = 128;                            // 1024 bits
{$IFDEF LargeBuffers}
  BlocksPerBuffer = 16384;                          // 1MiB BufferSize (32b block)
{$ELSE}
  BlocksPerBuffer = 64;                             // 4KiB BufferSize (32b block)
{$ENDIF}
  BufferSize      = BlocksPerBuffer * BlockSize_32; // Size of read buffer

  RoundConsts_32: Array[0..63] of LongWord = (
    $428A2F98, $71374491, $B5C0FBCF, $E9B5DBA5, $3956C25B, $59F111F1, $923F82A4, $AB1C5ED5,
    $D807AA98, $12835B01, $243185BE, $550C7DC3, $72BE5D74, $80DEB1FE, $9BDC06A7, $C19BF174,
    $E49B69C1, $EFBE4786, $0FC19DC6, $240CA1CC, $2DE92C6F, $4A7484AA, $5CB0A9DC, $76F988DA,
    $983E5152, $A831C66D, $B00327C8, $BF597FC7, $C6E00BF3, $D5A79147, $06CA6351, $14292967,
    $27B70A85, $2E1B2138, $4D2C6DFC, $53380D13, $650A7354, $766A0ABB, $81C2C92E, $92722C85,
    $A2BFE8A1, $A81A664B, $C24B8B70, $C76C51A3, $D192E819, $D6990624, $F40E3585, $106AA070,
    $19A4C116, $1E376C08, $2748774C, $34B0BCB5, $391C0CB3, $4ED8AA4A, $5B9CCA4F, $682E6FF3,
    $748F82EE, $78A5636F, $84C87814, $8CC70208, $90BEFFFA, $A4506CEB, $BEF9A3F7, $C67178F2);

  RoundConsts_64: Array[0..79] of QuadWord = (
    QuadWord($428A2F98D728AE22), QuadWord($7137449123EF65CD), QuadWord($B5C0FBCFEC4D3B2F), QuadWord($E9B5DBA58189DBBC),
    QuadWord($3956C25BF348B538), QuadWord($59F111F1B605D019), QuadWord($923F82A4AF194F9B), QuadWord($AB1C5ED5DA6D8118),
    QuadWord($D807AA98A3030242), QuadWord($12835B0145706FBE), QuadWord($243185BE4EE4B28C), QuadWord($550C7DC3D5FFB4E2),
    QuadWord($72BE5D74F27B896F), QuadWord($80DEB1FE3B1696B1), QuadWord($9BDC06A725C71235), QuadWord($C19BF174CF692694),
    QuadWord($E49B69C19EF14AD2), QuadWord($EFBE4786384F25E3), QuadWord($0FC19DC68B8CD5B5), QuadWord($240CA1CC77AC9C65),
    QuadWord($2DE92C6F592B0275), QuadWord($4A7484AA6EA6E483), QuadWord($5CB0A9DCBD41FBD4), QuadWord($76F988DA831153B5),
    QuadWord($983E5152EE66DFAB), QuadWord($A831C66D2DB43210), QuadWord($B00327C898FB213F), QuadWord($BF597FC7BEEF0EE4),
    QuadWord($C6E00BF33DA88FC2), QuadWord($D5A79147930AA725), QuadWord($06CA6351E003826F), QuadWord($142929670A0E6E70),
    QuadWord($27B70A8546D22FFC), QuadWord($2E1B21385C26C926), QuadWord($4D2C6DFC5AC42AED), QuadWord($53380D139D95B3DF),
    QuadWord($650A73548BAF63DE), QuadWord($766A0ABB3C77B2A8), QuadWord($81C2C92E47EDAEE6), QuadWord($92722C851482353B),
    QuadWord($A2BFE8A14CF10364), QuadWord($A81A664BBC423001), QuadWord($C24B8B70D0F89791), QuadWord($C76C51A30654BE30),
    QuadWord($D192E819D6EF5218), QuadWord($D69906245565A910), QuadWord($F40E35855771202A), QuadWord($106AA07032BBD1B8),
    QuadWord($19A4C116B8D2D0C8), QuadWord($1E376C085141AB53), QuadWord($2748774CDF8EEB99), QuadWord($34B0BCB5E19B48A8),
    QuadWord($391C0CB3C5C95A63), QuadWord($4ED8AA4AE3418ACB), QuadWord($5B9CCA4F7763E373), QuadWord($682E6FF3D6B2B8A3),
    QuadWord($748F82EE5DEFB2FC), QuadWord($78A5636F43172F60), QuadWord($84C87814A1F0AB72), QuadWord($8CC702081A6439EC),
    QuadWord($90BEFFFA23631E28), QuadWord($A4506CEBDE82BDE9), QuadWord($BEF9A3F7B2C67915), QuadWord($C67178F2E372532B),
    QuadWord($CA273ECEEA26619C), QuadWord($D186B8C721C0C207), QuadWord($EADA7DD6CDE0EB1E), QuadWord($F57D4F7FEE6ED178),
    QuadWord($06F067AA72176FBA), QuadWord($0A637DC5A2C898A6), QuadWord($113F9804BEF90DAE), QuadWord($1B710B35131C471B),
    QuadWord($28DB77F523047D84), QuadWord($32CAAB7B40C72493), QuadWord($3C9EBE0A15C9BEBC), QuadWord($431D67C49C100D4C),
    QuadWord($4CC5D4BECB3E42B6), QuadWord($597F299CFC657E2A), QuadWord($5FCB6FAB3AD6FAEC), QuadWord($6C44198C4A475817));

type
  TBlockBuffer_32 = Array[0..BlockSize_32 - 1] of Byte;
  TBlockBuffer_64 = Array[0..BlockSize_64 - 1] of Byte;

  TSHA2Context_Internal = record
    MessageHash:      TSHA2Hash;
    MessageLength:    OctaWord;
    TransferSize:     LongWord;
    TransferBuffer:   TBlockBuffer_64;
    ActiveBlockSize:  LongWord;
  end;
  PSHA2Context_Internal = ^TSHA2Context_Internal;

//==============================================================================

{$IFDEF FPC}{$ASMMODE intel}{$ENDIF}

Function EndianSwap(Value: LongWord): LongWord;{$IFNDEF PurePascal}assembler;{$ENDIF} overload;
{$IFDEF PurePascal}
begin
Result := (Value and $000000FF shl 24) or (Value and $0000FF00 shl 8) or
          (Value and $00FF0000 shr 8) or (Value and $FF000000 shr 24);
end;
{$ELSE}
asm
{$IFDEF x64}
  MOV     RAX, RCX
{$ENDIF}
  BSWAP   EAX
end;
{$ENDIF}
      
//------------------------------------------------------------------------------

Function EndianSwap(Value: QuadWord): QuadWord;{$IFNDEF PurePascal}assembler;{$ENDIF} overload;
{$IFDEF PurePascal}
begin
Int64Rec(Result).Hi := EndianSwap(Int64Rec(Value).Lo);
Int64Rec(Result).Lo := EndianSwap(Int64Rec(Value).Hi);
end;
{$ELSE}
asm
{$IFDEF x64}
  MOV     RAX, RCX
  BSWAP   RAX
{$ELSE}
  MOV     EAX, dword ptr [Value + 4]
  MOV     EDX, dword ptr [Value]
  BSWAP   EAX
  BSWAP   EDX
{$ENDIF}
end;
{$ENDIF}

//------------------------------------------------------------------------------

Function EndianSwap(Value: OctaWord): OctaWord; overload;
begin
Result.Hi := EndianSwap(Value.Lo);
Result.Lo := EndianSwap(Value.Hi);
end;

//------------------------------------------------------------------------------

Function RightRotate(Value: LongWord; Shift: Integer): LongWord;{$IFNDEF PurePascal}assembler;{$ENDIF} overload;
{$IFDEF PurePascal}
begin
  Result := (Value shr Shift) or (Value shl (32 - Shift));
end;
{$ELSE}
asm
{$IFDEF x64}
  MOV   EAX, ECX
{$ENDIF}
  MOV   CL,  DL
  ROR   EAX, CL
end;
{$ENDIF}

//------------------------------------------------------------------------------

Function RightRotate(Value: QuadWord; Shift: Integer): QuadWord;{$IFNDEF PurePascal}assembler;{$ENDIF} overload;
{$IFDEF PurePascal}
begin
Shift := Shift and $3F;
Result := (Value shr Shift) or (Value shl (64 - Shift));
end;
{$ELSE}
asm
{$IFDEF x64}
    MOV   RAX,  RCX
    MOV   CL,   DL
    ROR   RAX,  CL
{$ELSE}
    MOV   ECX,  EAX
    AND   ECX,  $3F
    CMP   ECX,  32

    JAE   @Above31

  @Below32:
    MOV   EAX,  dword ptr [Value]
    MOV   EDX,  dword ptr [Value + 4]
    CMP   ECX,  0
    JE    @FuncEnd

    MOV   dword ptr [Value],  EDX
    JMP   @Rotate

  @Above31:
    MOV   EDX,  dword ptr [Value]
    MOV   EAX,  dword ptr [Value + 4]
    JE    @FuncEnd

    AND   ECX,  $1F

  @Rotate:
    SHRD  EDX,  EAX, CL
    SHR   EAX,  CL
    PUSH  EAX
    MOV   EAX,  dword ptr [Value]
    XOR   CL,   31
    INC   CL
    SHL   EAX,  CL
    POP   ECX
    OR    EAX,  ECX

  @FuncEnd:
{$ENDIF}
end;
{$ENDIF}

//------------------------------------------------------------------------------

Function SizeToMessageLength(Size: QuadWord): OctaWord; overload;
begin
Result.Hi := Size shr 61;
Result.Lo := Size shl 3;
end;

//------------------------------------------------------------------------------

procedure IncOW(var Value: OctaWord; Increment: OctaWord); overload;
var
  Result: QuadWord;
  Carry:  LongWord;
  i:      Integer;
begin
Carry := 0;
For i := Low(Value.LongWords) to High(Value.LongWords) do
  begin
    Result := QuadWord(Carry) + Value.LongWords[i] + Increment.LongWords[i];
    Value.LongWords[i] := Int64Rec(Result).Lo;
    Carry := Int64Rec(Result).Hi;
  end;
end;

//==============================================================================

Function BlockHash_32(Hash: TSHA2Hash_32; const Block): TSHA2Hash_32;
var
  i:            Integer;
  Temp1,Temp2:  LongWord;
  Schedule:     Array[0..63] of LongWord;
  BlockWords:   Array[0..15] of LongWord absolute Block;
begin
Result := Hash;
For i := 0 to 15 do Schedule[i] := EndianSwap(BlockWords[i]);
For i := 16 to 63 do
  Schedule[i] := Schedule[i - 16] + (RightRotate(Schedule[i - 15],7) xor RightRotate(Schedule[i - 15],18) xor (Schedule[i - 15] shr 3)) +
                 Schedule[i - 7] + (RightRotate(Schedule[i - 2],17) xor RightRotate(Schedule[i - 2],19) xor (Schedule[i - 2] shr 10));
For i := 0 to 63 do
  begin
    Temp1 := Hash.PartH + (RightRotate(Hash.PartE,6) xor RightRotate(Hash.PartE,11) xor RightRotate(Hash.PartE,25)) +
             ((Hash.PartE and Hash.PartF) xor ((not Hash.PartE) and Hash.PartG)) + RoundConsts_32[i] + Schedule[i];
    Temp2 := (RightRotate(Hash.PartA,2) xor RightRotate(Hash.PartA,13) xor RightRotate(Hash.PartA,22)) +
             ((Hash.PartA and Hash.PartB) xor (Hash.PartA and Hash.PartC) xor (Hash.PartB and Hash.PartC));
    Hash.PartH := Hash.PartG;
    Hash.PartG := Hash.PartF;
    Hash.PartF := Hash.PartE;
    Hash.PartE := Hash.PartD + Temp1;
    Hash.PartD := Hash.PartC;
    Hash.PartC := Hash.PartB;
    Hash.PartB := Hash.PartA;
    Hash.PartA := Temp1 + Temp2;
  end;
Inc(Result.PartA,Hash.PartA);
Inc(Result.PartB,Hash.PartB);
Inc(Result.PartC,Hash.PartC);
Inc(Result.PartD,Hash.PartD);
Inc(Result.PartE,Hash.PartE);
Inc(Result.PartF,Hash.PartF);
Inc(Result.PartG,Hash.PartG);
Inc(Result.PartH,Hash.PartH);
end;

//------------------------------------------------------------------------------

Function BlockHash_64(Hash: TSHA2Hash_64; const Block): TSHA2Hash_64;
var
  i:            Integer;
  Temp1,Temp2:  QuadWord;
  Schedule:     Array[0..79] of QuadWord;
  BlockWords:   Array[0..15] of QuadWord absolute Block;
begin
Result := Hash;
For i := 0 to 15 do Schedule[i] := EndianSwap(BlockWords[i]);
For i := 16 to 79 do
  Schedule[i] := Schedule[i - 16] + (RightRotate(Schedule[i - 15],1) xor RightRotate(Schedule[i - 15],8) xor (Schedule[i - 15] shr 7)) +
                 Schedule[i - 7] + (RightRotate(Schedule[i - 2],19) xor RightRotate(Schedule[i - 2],61) xor (Schedule[i - 2] shr 6));
For i := 0 to 79 do
  begin
    Temp1 := Hash.PartH + (RightRotate(Hash.PartE,14) xor RightRotate(Hash.PartE,18) xor RightRotate(Hash.PartE,41)) +
             ((Hash.PartE and Hash.PartF) xor ((not Hash.PartE) and Hash.PartG)) + RoundConsts_64[i] + Schedule[i];
    Temp2 := (RightRotate(Hash.PartA,28) xor RightRotate(Hash.PartA,34) xor RightRotate(Hash.PartA,39)) +
             ((Hash.PartA and Hash.PartB) xor (Hash.PartA and Hash.PartC) xor (Hash.PartB and Hash.PartC));
    Hash.PartH := Hash.PartG;
    Hash.PartG := Hash.PartF;
    Hash.PartF := Hash.PartE;
    Hash.PartE := Hash.PartD + Temp1;
    Hash.PartD := Hash.PartC;
    Hash.PartC := Hash.PartB;
    Hash.PartB := Hash.PartA;
    Hash.PartA := Temp1 + Temp2;
  end;
Inc(Result.PartA,Hash.PartA);
Inc(Result.PartB,Hash.PartB);
Inc(Result.PartC,Hash.PartC);
Inc(Result.PartD,Hash.PartD);
Inc(Result.PartE,Hash.PartE);
Inc(Result.PartF,Hash.PartF);
Inc(Result.PartG,Hash.PartG);
Inc(Result.PartH,Hash.PartH);
end;

//==============================================================================
//------------------------------------------------------------------------------
//==============================================================================

Function BuildOctaWord(Lo,Hi: QuadWord): OctaWord;
begin
Result.Lo := Lo;
Result.Hi := Hi;
end;

//==============================================================================

Function InitialSHA2_512_224: TSHA2Hash_512_224;
var
  EvalStr: AnsiString;
begin
EvalStr := 'SHA-512/224';
Result := TSHA2Hash_512_224(LastBufferSHA2(InitialSHA2_512mod,PAnsiChar(EvalStr)^,Length(EvalStr) * SizeOf(AnsiChar)));
end;

//------------------------------------------------------------------------------

Function InitialSHA2_512_256: TSHA2Hash_512_256;
var
  EvalStr: AnsiString;
begin
EvalStr := 'SHA-512/256';
Result := TSHA2Hash_512_256(LastBufferSHA2(InitialSHA2_512mod,PAnsiChar(EvalStr)^,Length(EvalStr) * SizeOf(AnsiChar)));
end;

//==============================================================================
//------------------------------------------------------------------------------
//==============================================================================

Function SHA2ToStr_32(Hash: TSHA2Hash_32; Bits: Integer): String;
begin
Result := Copy(IntToHex(Hash.PartA,8) + IntToHex(Hash.PartB,8) +
            IntToHex(Hash.PartC,8) + IntToHex(Hash.PartD,8) +
            IntToHex(Hash.PartE,8) + IntToHex(Hash.PartF,8) +
            IntToHex(Hash.PartG,8) + IntToHex(Hash.PartH,8),1,Bits shr 2);
end;

//------------------------------------------------------------------------------

Function SHA2ToStr_64(Hash: TSHA2Hash_64; Bits: Integer): String;
begin
Result := Copy(IntToHex(Hash.PartA,16) + IntToHex(Hash.PartB,16) +
            IntToHex(Hash.PartC,16) + IntToHex(Hash.PartD,16) +
            IntToHex(Hash.PartE,16) + IntToHex(Hash.PartF,16) +
            IntToHex(Hash.PartG,16) + IntToHex(Hash.PartH,16),1,Bits shr 2);
end;

//------------------------------------------------------------------------------

Function SHA2ToStr(Hash: TSHA2Hash_224): String;
begin
Result := SHA2ToStr_32(TSHA2Hash_32(Hash),224);
end;

//------------------------------------------------------------------------------

Function SHA2ToStr(Hash: TSHA2Hash_256): String;
begin
Result := SHA2ToStr_32(TSHA2Hash_32(Hash),256);
end;

//------------------------------------------------------------------------------

Function SHA2ToStr(Hash: TSHA2Hash_384): String;
begin
Result := SHA2ToStr_64(TSHA2Hash_64(Hash),384);
end;

//------------------------------------------------------------------------------

Function SHA2ToStr(Hash: TSHA2Hash_512): String;
begin
Result := SHA2ToStr_64(TSHA2Hash_64(Hash),512);
end;

//------------------------------------------------------------------------------

Function SHA2ToStr(Hash: TSHA2Hash_512_224): String;
begin
Result := SHA2ToStr_64(TSHA2Hash_64(Hash),224);
end;

//------------------------------------------------------------------------------

Function SHA2ToStr(Hash: TSHA2Hash_512_256): String;
begin
Result := SHA2ToStr_64(TSHA2Hash_64(Hash),256);
end;

//------------------------------------------------------------------------------

Function SHA2ToStr(Hash: TSHA2Hash): String;
begin
case Hash.HashSize of
  sha224:     Result := SHA2ToStr(Hash.Hash224);
  sha256:     Result := SHA2ToStr(Hash.Hash256);
  sha384:     Result := SHA2ToStr(Hash.Hash384);
  sha512:     Result := SHA2ToStr(Hash.Hash512);
  sha512_224: Result := SHA2ToStr(Hash.Hash512_224);
  sha512_256: Result := SHA2ToStr(Hash.Hash512_256);
else
  raise Exception.CreateFmt('SHA2ToStr: Unknown hash size (%d)',[Integer(Hash.HashSize)]);
end;
end;

//==============================================================================

Function StrToSHA2_32(Str: String; Bits: Integer): TSHA2Hash_32;
var
  Characters: Integer;
  HashWords:  Array[0..7] of LongWord absolute Result;
  i:          Integer;
begin
Characters := Bits shr 2;
Str := Copy(Str,Length(Str) - Characters + 1,Characters);
If Length(Str) < Characters then
  Str := StringOfChar('0',Characters - Length(Str)) + Str
else
  If Length(Str) > Characters then
    Str := Copy(Str,Length(Str) - Characters + 1,Characters);
Str := Str + StringOfChar('0',64 - Length(Str));
For i := 0 to 7 do
  HashWords[i] := StrToInt('$' + Copy(Str,(i * 8) + 1,8));
end;

//------------------------------------------------------------------------------

Function StrToSHA2_64(Str: String; Bits: Integer): TSHA2Hash_64;
var
  Characters: Integer;
  HashWords:  Array[0..7] of QuadWord absolute Result;
  i:          Integer;
begin
Characters := Bits shr 2;
Str := Copy(Str,Length(Str) - Characters + 1,Characters);
If Length(Str) < Characters then
  Str := StringOfChar('0',Characters - Length(Str)) + Str
else
  If Length(Str) > Characters then
    Str := Copy(Str,Length(Str) - Characters + 1,Characters);
Str := Str + StringOfChar('0',128 - Length(Str));
For i := 0 to 7 do
  HashWords[i] := StrToInt64('$' + Copy(Str,(i * 16) + 1,16));
end;

//------------------------------------------------------------------------------

Function StrToSHA2_224(Str: String): TSHA2Hash_224;
begin
Result := TSHA2Hash_224(StrToSHA2_32(Str,224));
end;

//------------------------------------------------------------------------------

Function StrToSHA2_256(Str: String): TSHA2Hash_256;
begin
Result := TSHA2Hash_256(StrToSHA2_32(Str,256));
end;

//------------------------------------------------------------------------------

Function StrToSHA2_384(Str: String): TSHA2Hash_384;
begin
Result := TSHA2Hash_384(StrToSHA2_64(Str,384));
end;

//------------------------------------------------------------------------------

Function StrToSHA2_512(Str: String): TSHA2Hash_512;
begin
Result := TSHA2Hash_512(StrToSHA2_64(Str,512));
end;

//------------------------------------------------------------------------------

Function StrToSHA2_512_224(Str: String): TSHA2Hash_512_224;
begin
Result := TSHA2Hash_512_224(StrToSHA2_64(Str,224));
end;

//------------------------------------------------------------------------------

Function StrToSHA2_512_256(Str: String): TSHA2Hash_512_256;
begin
Result := TSHA2Hash_512_256(StrToSHA2_64(Str,256));
end;

//------------------------------------------------------------------------------

Function StrToSHA2(HashSize: TSHA2HashSize; Str: String): TSHA2Hash;
begin
Result.HashSize := HashSize;
case HashSize of
  sha224:     Result.Hash224 := StrToSHA2_224(Str);
  sha256:     Result.Hash256 := StrToSHA2_256(Str);
  sha384:     Result.Hash384 := StrToSHA2_384(Str);
  sha512:     Result.Hash512 := StrToSHA2_512(Str);
  sha512_224: Result.Hash512_224 := StrToSHA2_512_224(Str);
  sha512_256: Result.Hash512_256 := StrToSHA2_512_256(Str);
else
  raise Exception.CreateFmt('StrToSHA2: Unknown hash size (%d)',[Integer(HashSize)]);
end;
end;

//==============================================================================

Function TryStrToSHA2(const Str: String; out Hash: TSHA2Hash_224): Boolean;
begin
try
  Hash := StrToSHA2_224(Str);
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function TryStrToSHA2(const Str: String; out Hash: TSHA2Hash_256): Boolean;
begin
try
  Hash := StrToSHA2_256(Str);
  Result := True;
except
  Result := False;
end;
end;
//------------------------------------------------------------------------------

Function TryStrToSHA2(const Str: String; out Hash: TSHA2Hash_384): Boolean;
begin
try
  Hash := StrToSHA2_384(Str);
  Result := True;
except
  Result := False;
end;
end;
//------------------------------------------------------------------------------

Function TryStrToSHA2(const Str: String; out Hash: TSHA2Hash_512): Boolean;
begin
try
  Hash := StrToSHA2_512(Str);
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function TryStrToSHA2(const Str: String; out Hash: TSHA2Hash_512_224): Boolean;
begin
try
  Hash := StrToSHA2_512_224(Str);
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function TryStrToSHA2(const Str: String; out Hash: TSHA2Hash_512_256): Boolean;
begin
try
  Hash := StrToSHA2_512_256(Str);
  Result := True;
except
  Result := False;
end;
end;

//------------------------------------------------------------------------------

Function TryStrToSHA2(HashSize: TSHA2HashSize; const Str: String; out Hash: TSHA2Hash): Boolean;
begin
case HashSize of
  sha224:     Result := TryStrToSHA2(Str,Hash.Hash224);
  sha256:     Result := TryStrToSHA2(Str,Hash.Hash256);
  sha384:     Result := TryStrToSHA2(Str,Hash.Hash384);
  sha512:     Result := TryStrToSHA2(Str,Hash.Hash512);
  sha512_224: Result := TryStrToSHA2(Str,Hash.Hash512_224);
  sha512_256: Result := TryStrToSHA2(Str,Hash.Hash512_256);
else
  raise Exception.CreateFmt('TryStrToSHA2: Unknown hash size (%d)',[Integer(HashSize)]);
end;
end;

//==============================================================================

Function StrToSHA2Def(const Str: String; Default: TSHA2Hash_224): TSHA2Hash_224;
begin
If not TryStrToSHA2(Str,Result) then
  Result := Default;
end;

//------------------------------------------------------------------------------

Function StrToSHA2Def(const Str: String; Default: TSHA2Hash_256): TSHA2Hash_256;
begin
If not TryStrToSHA2(Str,Result) then
  Result := Default;
end;

//------------------------------------------------------------------------------

Function StrToSHA2Def(const Str: String; Default: TSHA2Hash_384): TSHA2Hash_384;
begin
If not TryStrToSHA2(Str,Result) then
  Result := Default;
end;

//------------------------------------------------------------------------------

Function StrToSHA2Def(const Str: String; Default: TSHA2Hash_512): TSHA2Hash_512;
begin
If not TryStrToSHA2(Str,Result) then
  Result := Default;
end;

//------------------------------------------------------------------------------

Function StrToSHA2Def(const Str: String; Default: TSHA2Hash_512_224): TSHA2Hash_512_224;
begin
If not TryStrToSHA2(Str,Result) then
  Result := Default;
end;

//------------------------------------------------------------------------------

Function StrToSHA2Def(const Str: String; Default: TSHA2Hash_512_256): TSHA2Hash_512_256;
begin
If not TryStrToSHA2(Str,Result) then
  Result := Default;
end;

//------------------------------------------------------------------------------

Function StrToSHA2Def(HashSize: TSHA2HashSize; const Str: String; Default: TSHA2Hash): TSHA2Hash;
begin
If HashSize = Default.HashSize then
  begin
    If not TryStrToSHA2(HashSize,Str,Result) then
      Result := Default;
  end
else raise Exception.CreateFmt('StrToSHA2Def: Required hash size differs from hash size of default value (%d,%d)',[Integer(HashSize),Integer(Default.HashSize)]);
end;

//==============================================================================

Function SameSHA2(A,B: TSHA2Hash_224): Boolean;
begin
Result := (A.PartA = B.PartA) and (A.PartB = B.PartB) and
          (A.PartC = B.PartC) and (A.PartD = B.PartD) and
          (A.PartE = B.PartE) and (A.PartF = B.PartF) and
          (A.PartG = B.PartG);
end;

//------------------------------------------------------------------------------

Function SameSHA2(A,B: TSHA2Hash_256): Boolean;
begin
Result := (A.PartA = B.PartA) and (A.PartB = B.PartB) and
          (A.PartC = B.PartC) and (A.PartD = B.PartD) and
          (A.PartA = B.PartE) and (A.PartF = B.PartF) and
          (A.PartG = B.PartG) and (A.PartH = B.PartH);
end;

//------------------------------------------------------------------------------

Function SameSHA2(A,B: TSHA2Hash_384): Boolean;
begin
Result := (A.PartA = B.PartA) and (A.PartB = B.PartB) and
          (A.PartC = B.PartC) and (A.PartD = B.PartD) and
          (A.PartA = B.PartE) and (A.PartF = B.PartF);
end;

//------------------------------------------------------------------------------

Function SameSHA2(A,B: TSHA2Hash_512): Boolean;
begin
Result := (A.PartA = B.PartA) and (A.PartB = B.PartB) and
          (A.PartC = B.PartC) and (A.PartD = B.PartD) and
          (A.PartA = B.PartE) and (A.PartF = B.PartF) and
          (A.PartG = B.PartG) and (A.PartH = B.PartH);
end;

//------------------------------------------------------------------------------

Function SameSHA2(A,B: TSHA2Hash_512_224): Boolean;
begin
Result := (A.PartA = B.PartA) and (A.PartB = B.PartB) and
          (A.PartC = B.PartC) and (Int64Rec(A.PartD).Hi = Int64Rec(B.PartD).Hi);
end;

//------------------------------------------------------------------------------

Function SameSHA2(A,B: TSHA2Hash_512_256): Boolean;
begin
Result := (A.PartA = B.PartA) and (A.PartB = B.PartB) and
          (A.PartC = B.PartC) and (A.PartD = B.PartD);
end;

//------------------------------------------------------------------------------

Function SameSHA2(A,B: TSHA2Hash): Boolean;
begin
If A.HashSize = B.HashSize then
  case A.HashSize of
    sha224:     Result := SameSHA2(A.Hash224,B.Hash224);
    sha256:     Result := SameSHA2(A.Hash256,B.Hash256);
    sha384:     Result := SameSHA2(A.Hash384,B.Hash384);
    sha512:     Result := SameSHA2(A.Hash512,B.Hash512);
    sha512_224: Result := SameSHA2(A.Hash512_224,B.Hash512_224);
    sha512_256: Result := SameSHA2(A.Hash512_256,B.Hash512_256);
  else
    raise Exception.CreateFmt('SameSHA2: Unknown hash size (%d)',[Integer(A.HashSize)]);
  end
else Result := False;
end;

//==============================================================================
//------------------------------------------------------------------------------
//==============================================================================

procedure BufferSHA2_32(var Hash: TSHA2Hash_32; const Buffer; Size: TSize);
type
  TBlocksArray = Array[0..0] of TBlockBuffer_32;
var
  i:  Integer;
begin
If (Size mod BlockSize_32) = 0 then
  begin
    For i := 0 to Pred(Size div BlockSize_32) do
      Hash := BlockHash_32(Hash,TBlocksArray(Buffer)[i]);
  end
else raise Exception.CreateFmt('BufferSHA2_32: Buffer size is not divisible by %d.',[BlockSize_32]);
end;

//------------------------------------------------------------------------------

procedure BufferSHA2_64(var Hash: TSHA2Hash_64; const Buffer; Size: TSize);
type
  TBlocksArray = Array[0..0] of TBlockBuffer_64;
var
  i:  Integer;
begin
If (Size mod BlockSize_64) = 0 then
  begin
    For i := 0 to Pred(Size div BlockSize_64) do
      Hash := BlockHash_64(Hash,TBlocksArray(Buffer)[i]);
  end
else raise Exception.CreateFmt('BufferSHA2_64: Buffer size is not divisible by %d.',[BlockSize_32]);
end;

//------------------------------------------------------------------------------

procedure BufferSHA2(var Hash: TSHA2Hash_224; const Buffer; Size: TSize);
begin
BufferSHA2_32(TSHA2Hash_32(Hash),Buffer,Size);
end;

//------------------------------------------------------------------------------

procedure BufferSHA2(var Hash: TSHA2Hash_256; const Buffer; Size: TSize);
begin
BufferSHA2_32(TSHA2Hash_32(Hash),Buffer,Size);
end;

//------------------------------------------------------------------------------

procedure BufferSHA2(var Hash: TSHA2Hash_384; const Buffer; Size: TSize);
begin
BufferSHA2_64(TSHA2Hash_64(Hash),Buffer,Size);
end;

//------------------------------------------------------------------------------

procedure BufferSHA2(var Hash: TSHA2Hash_512; const Buffer; Size: TSize);
begin
BufferSHA2_64(TSHA2Hash_64(Hash),Buffer,Size);
end;

//------------------------------------------------------------------------------

procedure BufferSHA2(var Hash: TSHA2Hash_512_224; const Buffer; Size: TSize);
begin
BufferSHA2_64(TSHA2Hash_64(Hash),Buffer,Size);
end;

//------------------------------------------------------------------------------

procedure BufferSHA2(var Hash: TSHA2Hash_512_256; const Buffer; Size: TSize);
begin
BufferSHA2_64(TSHA2Hash_64(Hash),Buffer,Size);
end;

//------------------------------------------------------------------------------

procedure BufferSHA2(var Hash: TSHA2Hash; const Buffer; Size: TSize);
begin
case Hash.HashSize of
  sha224:     BufferSHA2(Hash.Hash224,Buffer,Size);
  sha256:     BufferSHA2(Hash.Hash256,Buffer,Size);
  sha384:     BufferSHA2(Hash.Hash384,Buffer,Size);
  sha512:     BufferSHA2(Hash.Hash512,Buffer,Size);
  sha512_224: BufferSHA2(Hash.Hash512_224,Buffer,Size);
  sha512_256: BufferSHA2(Hash.Hash512_256,Buffer,Size);
else
  raise Exception.CreateFmt('BufferSHA2: Unknown hash size (%d)',[Integer(Hash.HashSize)]);
end;
end;

//==============================================================================

Function LastBufferSHA2_32(Hash: TSHA2Hash_32; const Buffer; Size: TSize; MessageLength: QuadWord): TSHA2Hash_32;
type
  TQuadWords = Array[0..0] of QuadWord;
var
  FullBlocks:     Integer;
  LastBlockSize:  Integer;
  HelpBlocks:     Integer;
  HelpBlocksBuff: Pointer;
begin
Result := Hash;
FullBlocks := Size div BlockSize_32;
If FullBlocks > 0 then BufferSHA2_32(Result,Buffer,FullBlocks * BlockSize_32);
LastBlockSize := Size - TSize(FullBlocks * BlockSize_32);
HelpBlocks := Ceil((LastBlockSize + SizeOf(QuadWord) + 1) / BlockSize_32);
HelpBlocksBuff := AllocMem(HelpBlocks * BlockSize_32);
try
  Move(TByteArray(Buffer)[FullBlocks * BlockSize_32],HelpBlocksBuff^,LastBlockSize);
  TByteArray(HelpBlocksBuff^)[LastBlockSize] := $80;
  TQuadWords(HelpBlocksBuff^)[HelpBlocks * (BlockSize_32 div SizeOf(QuadWord)) - 1] := EndianSwap(MessageLength);
  BufferSHA2_32(Result,HelpBlocksBuff^,HelpBlocks * BlockSize_32);
finally
  FreeMem(HelpBlocksBuff,HelpBlocks * BlockSize_32);
end;
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2_64(Hash: TSHA2Hash_64; const Buffer; Size: TSize; MessageLength: OctaWord): TSHA2Hash_64;
type
  TOctaWords = Array[0..0] of OctaWord;
var
  FullBlocks:     Integer;
  LastBlockSize:  Integer;
  HelpBlocks:     Integer;
  HelpBlocksBuff: Pointer;
begin
Result := Hash;
FullBlocks := Size div BlockSize_64;
If FullBlocks > 0 then BufferSHA2_64(Result,Buffer,FullBlocks * BlockSize_64);
LastBlockSize := Size - TSize(FullBlocks * BlockSize_64);
HelpBlocks := Ceil((LastBlockSize + SizeOf(OctaWord) + 1) / BlockSize_64);
HelpBlocksBuff := AllocMem(HelpBlocks * BlockSize_64);
try
  Move(TByteArray(Buffer)[FullBlocks * BlockSize_64],HelpBlocksBuff^,LastBlockSize);
  TByteArray(HelpBlocksBuff^)[LastBlockSize] := $80;
  TOctaWords(HelpBlocksBuff^)[HelpBlocks * (BlockSize_64 div SizeOf(OctaWord)) - 1] := EndianSwap(MessageLength);
  BufferSHA2_64(Result,HelpBlocksBuff^,HelpBlocks * BlockSize_64);
finally
  FreeMem(HelpBlocksBuff,HelpBlocks * BlockSize_64);
end;
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_224; const Buffer; Size: TSize; MessageLength: QuadWord): TSHA2Hash_224;
begin
Result := TSHA2Hash_224(LastBufferSHA2_32(TSHA2Hash_32(Hash),Buffer,Size,MessageLength));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_256; const Buffer; Size: TSize; MessageLength: QuadWord): TSHA2Hash_256;
begin
Result := TSHA2Hash_256(LastBufferSHA2_32(TSHA2Hash_32(Hash),Buffer,Size,MessageLength));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_384; const Buffer; Size: TSize; MessageLength: OctaWord): TSHA2Hash_384;
begin
Result := TSHA2Hash_384(LastBufferSHA2_64(TSHA2Hash_64(Hash),Buffer,Size,MessageLength));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_512; const Buffer; Size: TSize; MessageLength: OctaWord): TSHA2Hash_512;
begin
Result := TSHA2Hash_512(LastBufferSHA2_64(TSHA2Hash_64(Hash),Buffer,Size,MessageLength));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_512_224; const Buffer; Size: TSize; MessageLength: OctaWord): TSHA2Hash_512_224;
begin
Result := TSHA2Hash_512_224(LastBufferSHA2_64(TSHA2Hash_64(Hash),Buffer,Size,MessageLength));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_512_256; const Buffer; Size: TSize; MessageLength: OctaWord): TSHA2Hash_512_256;
begin
Result := TSHA2Hash_512_256(LastBufferSHA2_64(TSHA2Hash_64(Hash),Buffer,Size,MessageLength));
end;

//==============================================================================

Function LastBufferSHA2(Hash: TSHA2Hash_384; const Buffer; Size: TSize; MessageLengthLo: QuadWord): TSHA2Hash_384;
begin
Result := LastBufferSHA2(Hash,Buffer,Size,BuildOctaWord(MessageLengthLo,0));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_512; const Buffer; Size: TSize; MessageLengthLo: QuadWord): TSHA2Hash_512;
begin
Result := LastBufferSHA2(Hash,Buffer,Size,BuildOctaWord(MessageLengthLo,0));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_512_224; const Buffer; Size: TSize; MessageLengthLo: QuadWord): TSHA2Hash_512_224;
begin
Result := LastBufferSHA2(Hash,Buffer,Size,BuildOctaWord(MessageLengthLo,0));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_512_256; const Buffer; Size: TSize; MessageLengthLo: QuadWord): TSHA2Hash_512_256;
begin
Result := LastBufferSHA2(Hash,Buffer,Size,BuildOctaWord(MessageLengthLo,0));
end;

//==============================================================================

Function LastBufferSHA2(Hash: TSHA2Hash_384; const Buffer; Size: TSize; MessageLengthLo, MessageLengthHi: QuadWord): TSHA2Hash_384;
begin
Result := LastBufferSHA2(Hash,Buffer,Size,BuildOctaWord(MessageLengthLo,MessageLengthHi));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_512; const Buffer; Size: TSize; MessageLengthLo, MessageLengthHi: QuadWord): TSHA2Hash_512;
begin
Result := LastBufferSHA2(Hash,Buffer,Size,BuildOctaWord(MessageLengthLo,MessageLengthHi));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_512_224; const Buffer; Size: TSize; MessageLengthLo, MessageLengthHi: QuadWord): TSHA2Hash_512_224;
begin
Result := LastBufferSHA2(Hash,Buffer,Size,BuildOctaWord(MessageLengthLo,MessageLengthHi));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_512_256; const Buffer; Size: TSize; MessageLengthLo, MessageLengthHi: QuadWord): TSHA2Hash_512_256;
begin
Result := LastBufferSHA2(Hash,Buffer,Size,BuildOctaWord(MessageLengthLo,MessageLengthHi));
end;

//==============================================================================

Function LastBufferSHA2(Hash: TSHA2Hash; const Buffer; Size: TSize; MessageLength: QuadWord): TSHA2Hash;
begin
Result.HashSize := Hash.HashSize;
case Hash.HashSize of
  sha224:     Result.Hash224 := LastBufferSHA2(Hash.Hash224,Buffer,Size,MessageLength);
  sha256:     Result.Hash256 := LastBufferSHA2(Hash.Hash256,Buffer,Size,MessageLength);
  sha384:     Result.Hash384 := LastBufferSHA2(Hash.Hash384,Buffer,Size,BuildOctaWord(MessageLength,0));
  sha512:     Result.Hash512 := LastBufferSHA2(Hash.Hash512,Buffer,Size,BuildOctaWord(MessageLength,0));
  sha512_224: Result.Hash512_224 := LastBufferSHA2(Hash.Hash512_224,Buffer,Size,BuildOctaWord(MessageLength,0));
  sha512_256: Result.Hash512_256 := LastBufferSHA2(Hash.Hash512_256,Buffer,Size,BuildOctaWord(MessageLength,0));
else
  raise Exception.CreateFmt('LastBufferSHA2: Unknown hash size (%d)',[Integer(Hash.HashSize)]);
end;
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash; const Buffer; Size: TSize; MessageLengthLo, MessageLengthHi: QuadWord): TSHA2Hash;
begin
Result.HashSize := Hash.HashSize;
case Hash.HashSize of
  sha224:     Result.Hash224 := LastBufferSHA2(Hash.Hash224,Buffer,Size,MessageLengthLo);
  sha256:     Result.Hash256 := LastBufferSHA2(Hash.Hash256,Buffer,Size,MessageLengthLo);
  sha384:     Result.Hash384 := LastBufferSHA2(Hash.Hash384,Buffer,Size,BuildOctaWord(MessageLengthLo,MessageLengthHi));
  sha512:     Result.Hash512 := LastBufferSHA2(Hash.Hash512,Buffer,Size,BuildOctaWord(MessageLengthLo,MessageLengthHi));
  sha512_224: Result.Hash512_224 := LastBufferSHA2(Hash.Hash512_224,Buffer,Size,BuildOctaWord(MessageLengthLo,MessageLengthHi));
  sha512_256: Result.Hash512_256 := LastBufferSHA2(Hash.Hash512_256,Buffer,Size,BuildOctaWord(MessageLengthLo,MessageLengthHi));
else
  raise Exception.CreateFmt('LastBufferSHA2: Unknown hash size (%d)',[Integer(Hash.HashSize)]);
end;
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash; const Buffer; Size: TSize; MessageLength: OctaWord): TSHA2Hash;
begin
Result.HashSize := Hash.HashSize;
case Hash.HashSize of
  sha224:     Result.Hash224 := LastBufferSHA2(Hash.Hash224,Buffer,Size,MessageLength.Lo);
  sha256:     Result.Hash256 := LastBufferSHA2(Hash.Hash256,Buffer,Size,MessageLength.Lo);
  sha384:     Result.Hash384 := LastBufferSHA2(Hash.Hash384,Buffer,Size,MessageLength);
  sha512:     Result.Hash512 := LastBufferSHA2(Hash.Hash512,Buffer,Size,MessageLength);
  sha512_224: Result.Hash512_224 := LastBufferSHA2(Hash.Hash512_224,Buffer,Size,MessageLength);
  sha512_256: Result.Hash512_256 := LastBufferSHA2(Hash.Hash512_256,Buffer,Size,MessageLength);
else
  raise Exception.CreateFmt('LastBufferSHA2: Unknown hash size (%d)',[Integer(Hash.HashSize)]);
end;
end;

//==============================================================================

Function LastBufferSHA2(Hash: TSHA2Hash_224; const Buffer; Size: TSize): TSHA2Hash_224;
begin
Result := TSHA2Hash_224(LastBufferSHA2_32(TSHA2Hash_32(Hash),Buffer,Size,QuadWord(Size) shl 3));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_256; const Buffer; Size: TSize): TSHA2Hash_256;
begin
Result := TSHA2Hash_256(LastBufferSHA2_32(TSHA2Hash_32(Hash),Buffer,Size,QuadWord(Size) shl 3));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_384; const Buffer; Size: TSize): TSHA2Hash_384;
begin
Result := TSHA2Hash_384(LastBufferSHA2_64(TSHA2Hash_64(Hash),Buffer,Size,SizeToMessageLength(Size)));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_512; const Buffer; Size: TSize): TSHA2Hash_512;
begin
Result := TSHA2Hash_512(LastBufferSHA2_64(TSHA2Hash_64(Hash),Buffer,Size,SizeToMessageLength(Size)));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_512_224; const Buffer; Size: TSize): TSHA2Hash_512_224;
begin
Result := TSHA2Hash_512_224(LastBufferSHA2_64(TSHA2Hash_64(Hash),Buffer,Size,SizeToMessageLength(Size)));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash_512_256; const Buffer; Size: TSize): TSHA2Hash_512_256;
begin
Result := TSHA2Hash_512_256(LastBufferSHA2_64(TSHA2Hash_64(Hash),Buffer,Size,SizeToMessageLength(Size)));
end;

//------------------------------------------------------------------------------

Function LastBufferSHA2(Hash: TSHA2Hash; const Buffer; Size: TSize): TSHA2Hash;
begin
Result.HashSize := Hash.HashSize;
case Hash.HashSize of
  sha224:     Result.Hash224 := LastBufferSHA2(Hash.Hash224,Buffer,Size);
  sha256:     Result.Hash256 := LastBufferSHA2(Hash.Hash256,Buffer,Size);
  sha384:     Result.Hash384 := LastBufferSHA2(Hash.Hash384,Buffer,Size);
  sha512:     Result.Hash512 := LastBufferSHA2(Hash.Hash512,Buffer,Size);
  sha512_224: Result.Hash512_224 := LastBufferSHA2(Hash.Hash512_224,Buffer,Size);
  sha512_256: Result.Hash512_256 := LastBufferSHA2(Hash.Hash512_256,Buffer,Size);
else
  raise Exception.CreateFmt('LastBufferSHA2: Unknown hash size (%d)',[Integer(Hash.HashSize)]);
end;
end;

//==============================================================================
//------------------------------------------------------------------------------
//==============================================================================

Function BufferSHA2(HashSize: TSHA2HashSize; const Buffer; Size: TSize): TSHA2Hash;
begin
Result.HashSize := HashSize;
case HashSize of
  sha224:     Result.Hash224 := LastBufferSHA2(InitialSHA2_224,Buffer,Size);
  sha256:     Result.Hash256 := LastBufferSHA2(InitialSHA2_256,Buffer,Size);
  sha384:     Result.Hash384 := LastBufferSHA2(InitialSHA2_384,Buffer,Size);
  sha512:     Result.Hash512 := LastBufferSHA2(InitialSHA2_512,Buffer,Size);
  sha512_224: Result.Hash512_224 := LastBufferSHA2(InitialSHA2_512_224,Buffer,Size);
  sha512_256: Result.Hash512_256 := LastBufferSHA2(InitialSHA2_512_256,Buffer,Size);
else
  raise Exception.CreateFmt('BufferSHA2: Unknown hash size (%d)',[Integer(HashSize)]);
end;
end;

//==============================================================================

Function AnsiStringSHA2(HashSize: TSHA2HashSize; const Str: AnsiString): TSHA2Hash;
{$IFDEF UseStringStream}
var
  StringStream: TStringStream;
begin
StringStream := TStringStream.Create(Str);
try
  Result := StreamSHA2(HashSize,StringStream);
finally
  StringStream.Free;
end;
end;
{$ELSE}
begin
Result := BufferSHA2(HashSize,PAnsiChar(Str)^,Length(Str) * SizeOf(AnsiChar));
end;
{$ENDIF}

//------------------------------------------------------------------------------

Function WideStringSHA2(HashSize: TSHA2HashSize; const Str: WideString): TSHA2Hash;
{$IFDEF UseStringStream}
var
  StringStream: TStringStream;
begin
StringStream := TStringStream.Create(Str);
try
  Result := StreamSHA2(HashSize,StringStream);
finally
  StringStream.Free;
end;
end;
{$ELSE}
begin
Result := BufferSHA2(HashSize,PWideChar(Str)^,Length(Str) * SizeOf(WideChar));
end;
{$ENDIF}

//------------------------------------------------------------------------------

Function StringSHA2(HashSize: TSHA2HashSize; const Str: String): TSHA2Hash;
{$IFDEF UseStringStream}
var
  StringStream: TStringStream;
begin
StringStream := TStringStream.Create(Str);
try
  Result := StreamSHA2(HashSize,StringStream);
finally
  StringStream.Free;
end;
end;
{$ELSE}
begin
Result := BufferSHA2(HashSize,PChar(Str)^,Length(Str) * SizeOf(Char));
end;
{$ENDIF}

//==============================================================================

Function StreamSHA2(HashSize: TSHA2HashSize; Stream: TStream; Count: Int64 = -1): TSHA2Hash;
var
  Buffer:         Pointer;
  BytesRead:      TSize;
  MessageLength:  OctaWord;
begin
If Assigned(Stream) then
  begin
    If Count = 0 then
      Count := Stream.Size - Stream.Position;
    If Count < 0 then
      begin
        Stream.Position := 0;
        Count := Stream.Size;
      end;
    MessageLength := SizeToMessageLength(QuadWord(Count));
    GetMem(Buffer,BufferSize);
    try
      Result.HashSize := HashSize;
      case HashSize of
        sha224:     Result.Hash224 := InitialSHA2_224;
        sha256:     Result.Hash256 := InitialSHA2_256;
        sha384:     Result.Hash384 := InitialSHA2_384;
        sha512:     Result.Hash512 := InitialSHA2_512;
        sha512_224: Result.Hash512_224 := InitialSHA2_512_224;
        sha512_256: Result.Hash512_256 := InitialSHA2_512_256;
      else
        raise Exception.CreateFmt('StreamSHA2: Unknown hash size (%d)',[Integer(HashSize)]);
      end;
      repeat
        BytesRead := Stream.Read(Buffer^,Min(BufferSize,Count));
        If QuadWord(BytesRead) < BufferSize then
          Result := LastBufferSHA2(Result,Buffer^,BytesRead,MessageLength)
        else
          BufferSHA2(Result,Buffer^,BytesRead);
        Dec(Count,BytesRead);
      until BytesRead < BufferSize;
    finally
      FreeMem(Buffer,BufferSize);
    end;
  end
else raise Exception.Create('StreamSHA2: Stream is not assigned.');
end;

//------------------------------------------------------------------------------

Function FileSHA2(HashSize: TSHA2HashSize; const FileName: String): TSHA2Hash;
var
  FileStream: TFileStream;
begin
FileStream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
try
  Result := StreamSHA2(HashSize,FileStream);
finally
  FileStream.Free;
end;
end;

//==============================================================================
//------------------------------------------------------------------------------
//==============================================================================

Function SHA2_Init(HashSize: TSHA2HashSize): TSHA2Context;
begin
Result := AllocMem(SizeOf(TSHA2Context_Internal));
with PSHA2Context_Internal(Result)^ do
  begin
    MessageHash.HashSize := HashSize;
    case HashSize of
      sha224:     MessageHash.Hash224 := InitialSHA2_224;
      sha256:     MessageHash.Hash256 := InitialSHA2_256;
      sha384:     MessageHash.Hash384 := InitialSHA2_384;
      sha512:     MessageHash.Hash512 := InitialSHA2_512;
      sha512_224: MessageHash.Hash512_224 := InitialSHA2_512_224;
      sha512_256: MessageHash.Hash512_256 := InitialSHA2_512_256;
    else
      raise Exception.CreateFmt('SHA2_Hash: Unknown hash size (%d)',[Integer(HashSize)]);
    end;
    If HashSize in [sha224,sha256] then
      ActiveBlockSize := BlockSize_32
    else
      ActiveBlockSize := BlockSize_64;
    MessageLength := ZeroOctaWord;
    TransferSize := 0;
  end;
end;

//------------------------------------------------------------------------------

procedure SHA2_Update(Context: TSHA2Context; const Buffer; Size: TSize);
var
  FullChunks:     LongWord;
  RemainingSize:  TSize;
begin
with PSHA2Context_Internal(Context)^ do
  begin
    If TransferSize > 0 then
      begin
        If Size >= (ActiveBlockSize - TransferSize) then
          begin
            IncOW(MessageLength,SizeToMessageLength(ActiveBlockSize - TransferSize));
            Move(Buffer,TransferBuffer[TransferSize],ActiveBlockSize - TransferSize);
            BufferSHA2(MessageHash,TransferBuffer,ActiveBlockSize);
            RemainingSize := Size - (ActiveBlockSize - TransferSize);
            TransferSize := 0;
            SHA2_Update(Context,TByteArray(Buffer)[Size - RemainingSize],RemainingSize);
          end
        else
          begin
            IncOW(MessageLength,SizeToMessageLength(Size));
            Move(Buffer,TransferBuffer[TransferSize],Size);
            Inc(TransferSize,Size);
          end;  
      end
    else
      begin
        IncOW(MessageLength,SizeToMessageLength(Size));
        FullChunks := Size div ActiveBlockSize;
        BufferSHA2(MessageHash,Buffer,FullChunks * ActiveBlockSize);
        If TSize(FullChunks * ActiveBlockSize) < Size then
          begin
            TransferSize := Size - TSize(FullChunks * QuadWord(ActiveBlockSize));
            Move(TByteArray(Buffer)[Size - TransferSize],TransferBuffer,TransferSize);
          end;
      end;
  end;
end;

//------------------------------------------------------------------------------

Function SHA2_Final(var Context: TSHA2Context; const Buffer; Size: TSize): TSHA2Hash;
begin
SHA2_Update(Context,Buffer,Size);
Result := SHA2_Final(Context);
end;

//------------------------------------------------------------------------------

Function SHA2_Final(var Context: TSHA2Context): TSHA2Hash;
begin
with PSHA2Context_Internal(Context)^ do
  Result := LastBufferSHA2(MessageHash,TransferBuffer,TransferSize,MessageLength);
FreeMem(Context,SizeOf(TSHA2Context_Internal));
Context := nil;
end;

//------------------------------------------------------------------------------

Function SHA2_Hash(HashSize: TSHA2HashSize; const Buffer; Size: TSize): TSHA2Hash;
begin
Result.HashSize := HashSize;
case HashSize of
  sha224:     Result.Hash224 := InitialSHA2_224;
  sha256:     Result.Hash256 := InitialSHA2_256;
  sha384:     Result.Hash384 := InitialSHA2_384;
  sha512:     Result.Hash512 := InitialSHA2_512;
  sha512_224: Result.Hash512_224 := InitialSHA2_512_224;
  sha512_256: Result.Hash512_256 := InitialSHA2_512_256;
else
  raise Exception.CreateFmt('SHA2_Hash: Unknown hash size (%d)',[Integer(HashSize)]);
end;
Result := LastBufferSHA2(Result,Buffer,Size,SizeToMessageLength(Size));
end;

end.
