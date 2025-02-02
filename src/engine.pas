{
  RetroTetris - A simple Tetris game
  Copyright (c) 2024 Wildy Sheverando <hai@shiwildy.com>

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.

  This software is a modified and redeveloped version of the
  original submitted by Eny, which can be found at:
  https://github.com/eny-fpc/petris
}

unit Engine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  C_BOARD_WIDTH        = 10;
  C_BOARD_PLAYHEIGHT   = 20;
  C_BOARD_HEIGHT       = C_BOARD_PLAYHEIGHT + 2;
  C_HISTORY_STACK      = 4;
  C_HISTORY_RETRY      = 5;
  C_ROWS_TO_NEXT_LEVEL = 10;

type
  TtetrisGameState      = ( gsReady, gsFalling, gsLockDown, gsEnded );
  TPetriminoOrientation = ( poNorth, poEast, poSouth, poWest );
  TPetriminoType        = ( pmtO, pmtI, pmtT, pmtL, pmtJ, pmtS, pmtZ );
  TtetrisCellState      = ( pssOpen, pssMino, pssOccupied );
  TtetrisMatrixCell = record
    CellState: TtetrisCellState;
    MinoType: TPetriminoType;
  end;
  TtetrisMatrix = array[1..C_BOARD_WIDTH, 1..C_BOARD_HEIGHT] of TtetrisMatrixCell;

  TPetriminoCountArray = array[TPetriminoType] of integer;
  TPetriminoStack = array[0..C_HISTORY_STACK-1] of TPetriminoType;

  { TPetrimino }

  TMinosArray = array[0..3] of TPoint;
  TPetrimino = class
  private
    FOrientation: TPetriminoOrientation;
    FPetriminoType: TPetriminoType;
    FMinos: TMinosArray;
    FTopLeft: TPoint;

    procedure SetUpMinos;
    procedure SetOrientation(pValue: TPetriminoOrientation);
    procedure SetPetriminoType(pValue: TPetriminoType);

  public
    procedure MoveDown;
    procedure MoveRel( const pDeltaX, pDeltaY: integer );
    function Position( const pMino: integer): TPoint;

    property Orientation: TPetriminoOrientation read FOrientation write SetOrientation;
    property PetriminoType: TPetriminoType read FPetriminoType write SetPetriminoType;
    property TopLeft: TPoint read FTopLeft write FTopLeft;
  end;

  { TtetrisGame }
  TtetrisGame = class;
  TtetrisGameNotifyEvent = procedure( pGame: TtetrisGame ) of object;

  TtetrisGame = class
  private
    FMatrix: TtetrisMatrix;
    FCurrent: TPetrimino;
    FOnPipelineChanged: TtetrisGameNotifyEvent;
    FPipeLine: TPetrimino;
    FInternalGameState: TtetrisGameState;
    FScore: integer;
    FLevel: integer;
    FOnEnterFallingPhase: TtetrisGameNotifyEvent;
    FOnEnterLockPhase: TtetrisGameNotifyEvent;
    FOnGameEnded: TtetrisGameNotifyEvent;
    FOnMatrixChanged: TtetrisGameNotifyEvent;
    FHistory: TPetriminoStack;
    FPetriminoCount: TPetriminoCountArray;
    FRowsDeleted: integer;

    procedure BlockToBoard( const pBlock: TPetrimino; const pNewState: TtetrisCellState = pssMino);
    procedure BlockFromBoard( const pBlock: TPetrimino);
    function GetMatrixCell(const pCol, pRow: integer): TtetrisMatrixCell;
    procedure NextInPipeline;
    procedure SetInternalGameState(pValue: TtetrisGameState);
    procedure GenerateNextPetrimino;
    procedure CheckEnterLockPhase;
    function  CurrentCanMoveDown: boolean;
    procedure MoveBlock( const pDeltaX, pDeltaY: integer);
    procedure MoveHorizontal( const pDeltaX: integer );
    procedure MoveVertical;
    procedure FixateBlock;
    procedure GetNextBlock;
    procedure Execute( const pNotifyEvent: TtetrisGameNotifyEvent );
    function OrientationOK(const pNewOrientation: TPetriminoOrientation): boolean;
    procedure IncreaseScore(const pPoints: integer);
    procedure CheckForPatterns;

    property InternalGameState: TtetrisGameState read FInternalGameState write SetInternalGameState;

  public
    constructor Create;
    destructor Destroy; override;

    procedure Next;
    function  GameState: TtetrisGameState;
    procedure MoveLeft;
    procedure MoveRight;
    procedure RotateClockwise;
    procedure DropBlockDown;
    function  PetriminoCount( const pType: TPetriminoType ): integer;

    property Level: integer read FLevel write FLevel;
    property Score: integer read FScore;
    property Mino[const pCol, pRow: integer]: TtetrisMatrixCell read GetMatrixCell; default;
    property PipeLine: TPetrimino read FPipeLine;

    // Notify events for the GUI
    property OnMatrixChanged: TtetrisGameNotifyEvent read FOnMatrixChanged write FOnMatrixChanged;
    property OnEnterFallingPhase: TtetrisGameNotifyEvent read FOnEnterFallingPhase write FOnEnterFallingPhase;
    property OnEnterLockPhase: TtetrisGameNotifyEvent read FOnEnterLockPhase write FOnEnterLockPhase;
    property OnEndGame: TtetrisGameNotifyEvent read FOnGameEnded write FOnGameEnded;
    property OnPipelineChanged: TtetrisGameNotifyEvent read FOnPipelineChanged write FOnPipelineChanged;
  end;

const
  C_PETRIMINOS: array[TPetriminoType, TPetriminoOrientation ] of integer =
      (
        ( %0110011000000000, %0110011000000000, %0110011000000000, %0110011000000000 ), // O
        ( %0000111100000000, %0010001000100010, %0000000011110000, %0100010001000100 ), // I
        ( %0100111000000000, %0100011001000000, %0000111001000000, %0100110001000000 ), // T
        ( %0010111000000000, %0100010001100000, %0000111010000000, %1100010001000000 ), // L
        ( %1000111000000000, %0110010001000000, %0000111000100000, %0100010011000000 ), // J
        ( %0110110000000000, %0100011000100000, %0000011011000000, %1000110001000000 ), // S
        ( %1100011000000000, %0010011001000000, %0000110001100000, %0100110010000000 )  // Z
      );

implementation

{ TPetrimino }

procedure TPetrimino.MoveRel(const pDeltaX, pDeltaY: integer);
begin
  with FTopLeft do
  begin
    inc(X, pDeltaX);
    inc(Y, pDeltaY)
  end;
end;

function TPetrimino.Position(const pMino: integer): TPoint;
begin
  with result do
  begin
    X := FTopLeft.X + FMinos[pMino].x;
    Y := FTopLeft.Y + FMinos[pMino].y;
  end;
end;

procedure TPetrimino.SetUpMinos;
var MinoMask: integer;
    Col,Row : integer;
    MinoNum : integer;
begin
  MinoMask := C_PETRIMINOS[PetriminoType, Orientation];
  MinoNum := 0;
  for row := 0 to 3 do
    if MinoNum < 4 then
      for col := 0 to 3 do
      begin
        // Mino position found?
        if MinoMask and (%1000000000000000) = %1000000000000000 then
        begin
          FMinos[MinoNum] := Point(col,-row); // Note that rows count down hence minus
          inc(MinoNum);
          if MinoNum = 4 then break;
        end;
        // Next bit position
        MinoMask := MinoMask shl 1;
      end
end;

procedure TPetrimino.SetOrientation(pValue: TPetriminoOrientation);
begin
  if FOrientation = pValue then Exit;
  FOrientation := pValue;
  SetUpMinos;
end;

procedure TPetrimino.SetPetriminoType(pValue: TPetriminoType);
begin
  if FPetriminoType = pValue then Exit;
  FPetriminoType := pValue;
  SetUpMinos;
end;

procedure TPetrimino.MoveDown;
begin
  MoveRel(0, -1)
end;

{ TtetrisGame }

constructor TtetrisGame.Create;
begin
  // Init some values
  FInternalGameState := gsReady;
  FLevel             := 1;
  fillchar(FMatrix, sizeof(FMatrix), 0);
  fillchar(FPetriminoCount, sizeof(FPetriminoCount), 0);

  FCurrent := TPetrimino.Create;   // Petrimino to control by the user
  FPipeLine := TPetrimino.Create;  // Pipeline (next petrimino)

  // Start history: try not to start with any of the shapes below
  FHistory[0] := pmtS;
  FHistory[1] := pmtZ;
  FHistory[2] := pmtS;
  FHistory[2] := pmtZ;
end;

destructor TtetrisGame.Destroy;
begin
  FPipeLine.Free;
  FCurrent.Free;
  inherited Destroy;
end;

function TtetrisGame.GameState: TtetrisGameState;
begin
  result := InternalGameState;
end;

procedure TtetrisGame.SetInternalGameState(pValue: TtetrisGameState);
begin
  if FInternalGameState = pValue then Exit;
  FInternalGameState := pValue;
end;

procedure TtetrisGame.Execute(const pNotifyEvent: TtetrisGameNotifyEvent);
begin
  if assigned(pNotifyEvent) then
    pNotifyEvent( self );
end;

procedure TtetrisGame.IncreaseScore(const pPoints: integer);
begin
  inc(FScore, pPoints)
end;

function TtetrisGame.OrientationOK(const pNewOrientation: TPetriminoOrientation): boolean;
var CurrentOrientation: TPetriminoOrientation;
    i: integer;
begin
  // Keep the current orientation for backup and set to the new one for testing
  CurrentOrientation := FCurrent.Orientation;
  FCurrent.Orientation := pNewOrientation;

  // Check if all new positions are within the board and fit
  result := true; // Assume all is ok
  for i := 0 to 3 do
    with FCurrent.Position(i) do
      if (X < 1) or
         (X > C_BOARD_WIDTH) or (Y < 1) or
         (Mino[X,Y].CellState = pssOccupied)
      then
        begin
          result := false;
          break
        end;

  // Reset orientation
  FCurrent.Orientation := CurrentOrientation;
end;

procedure TtetrisGame.CheckForPatterns;
var row, col   : integer;
    WorldRow   : integer;
    uprow      : integer;
    RowsDeleted: integer;
    RowFull    : boolean;
begin
  // Check for the max 4 rows of the current block
  RowsDeleted := 0;
  for row := 0 to 3 do
  begin
    // Translate relative row number to number in the matrix and check if valid
    WorldRow := FCurrent.TopLeft.y - row;
    if WorldRow < 1 then break;

    RowFull := true; // Assume the row is full
    for col := 1 to 10 do
      if Mino[col, WorldRow].CellState <> pssOccupied then
      begin
        // An empty cell was found --> stop checking the row is not full
        RowFull := false;
        break
      end;

    // Row to delete?
    if RowFull then
    begin
      inc(RowsDeleted);
      for uprow := WorldRow to C_BOARD_HEIGHT-1 do
        for col := 1 to 10 do
          FMatrix[col, uprow].CellState := Mino[col, uprow+1].CellState;
    end;
  end;

  // When rows deleted add to the score and signal a board change
  if RowsDeleted > 0 then
  begin
    inc(FRowsDeleted, RowsDeleted);
    if FRowsDeleted > C_ROWS_TO_NEXT_LEVEL then
    begin
      inc(Flevel);
      FRowsDeleted := 0;
    end;
    IncreaseScore(level * 20 * (RowsDeleted * RowsDeleted));
    Execute( FOnMatrixChanged );
  end;
end;

procedure TtetrisGame.BlockToBoard(const pBlock: TPetrimino; const pNewState: TtetrisCellState);
var i: integer;
begin
  for i := 0 to 3 do
    with pBlock.Position(i) do
    begin
      FMatrix[X,Y].CellState := pNewState;
      FMatrix[X,Y].MinoType  := pBlock.FPetriminoType;
    end;
end;

procedure TtetrisGame.BlockFromBoard(const pBlock: TPetrimino);
var i: integer;
begin
  for i := 0 to 3 do
    with pBlock.Position(i) do
      FMatrix[ X,Y].CellState := pssOpen
end;

function TtetrisGame.GetMatrixCell(const pCol, pRow: integer): TtetrisMatrixCell;
begin
  result := FMatrix[pCol, pRow]
end;

procedure TtetrisGame.NextInPipeline;
var j,h: integer;
    InHistory: boolean;
    NextPT: TPetriminoType;
begin
  j := C_HISTORY_RETRY;
  repeat
    // Next index - check if it is in the history
    NextPT := TPetriminoType(random(7));
    InHistory := false;
    for h := 0 to C_HISTORY_STACK-1 do
      if FHistory[h] = NextPT then
      begin
        // Found the new block in the history - skip it
        dec(j);
        InHistory := true;
        break;
      end;

    // If not in history then the block type can be chosen
    if not InHistory then j := 0;
  until j = 0;

  FPipeLine.PetriminoType := TPetriminoType(NextPT);
  Execute( FOnPipelineChanged );

  // Update the history
  for h := C_HISTORY_STACK-1 downto 1 do
    FHistory[h] := FHistory[h-1];
  FHistory[0] := NextPT;
end;

procedure TtetrisGame.GenerateNextPetrimino;
begin
  // Get the next block in line; add it to the board above the matrix and drop one down
  // so it falls in view (top line of the matrix).
  GetNextBlock;
  BlockToBoard(FCurrent);
  InternalGameState := gsFalling;
  MoveVertical;
end;

function TtetrisGame.CurrentCanMoveDown: boolean;
var i: integer;
begin
  // Check if all minos in the current block can go down one position
  result := false; // Assume it will fail
  for i := 0 to 3 do
    with FCurrent.Position(i) do
      if (y = 1) or (Mino[X, Y-1].CellState = pssOccupied) then
        exit;

  // All has gone well: the block can drop
  result := true;
end;

procedure TtetrisGame.MoveBlock(const pDeltaX, pDeltaY: integer);
begin
  // Execute the block movement
  BlockFromBoard(FCurrent);
  FCurrent.MoveRel(pDeltaX, pDeltaY);
  BlockToBoard(FCurrent);

  // Notify the GUI about the update
  Execute( FOnMatrixChanged );

  // Check if the  movement resulted in a lock state (hit another block below)
  CheckEnterLockPhase;
end;

procedure TtetrisGame.MoveVertical;
begin
  if not CurrentCanMoveDown then
    InternalGameState := gsEnded
  else
    begin
      // Update score here, move the block and check if the block has entered the falling state
      IncreaseScore(Level); // Simple scoring mechanism
      MoveBlock(0, -1);
      if InternalGameState = gsFalling then
        Execute( FOnEnterFallingPhase );
    end;
end;

procedure TtetrisGame.CheckEnterLockPhase;
begin
  // Check if the block can move down one square. If not, trigger the lock down delay
  if CurrentCanMoveDown then
    InternalGameState := gsFalling
  else
    if InternalGameState <> gsLockDown then // Only trigger if not yet in locked state
    begin;
      InternalGameState := gsLockDown;
      Execute( OnEnterLockPhase )
    end;
end;

procedure TtetrisGame.FixateBlock;
begin
  BlockToBoard(FCurrent, pssOccupied);
  CheckForPatterns;
  GenerateNextPetrimino;
end;

procedure TtetrisGame.GetNextBlock;
begin
  // Move the next block from the pipeline to the active one
  FCurrent.PetriminoType := PipeLine.PetriminoType;
  FCurrent.TopLeft       := Point((C_BOARD_WIDTH div 2) - 1, C_BOARD_PLAYHEIGHT + 2);
  Fcurrent.Orientation   := poNorth;

  // Update the block count for statistical reasons (gui can show the blocks used so far)
  FPetriminoCount[FCurrent.PetriminoType] := FPetriminoCount[FCurrent.PetriminoType] + 1;

  // Put a new block in the pipeline
  NextInPipeline;
end;

procedure TtetrisGame.MoveHorizontal(const pDeltaX: integer);
var i       : integer;
    NewCol  : integer;
    OldState: TtetrisGameState;
begin
  // Abort if the block would violate the board constraints or ends on a fixed cell
  for i := 0 to 3 do
    with FCurrent.Position(i) do
    begin
      NewCol := X + pDeltaX;
      if (NewCol < 1) or (NewCol > C_BOARD_WIDTH) then
        exit;

      // Is the position in the board occupied?
      if Mino[NewCol, Y].CellState = pssOccupied then
        exit;
    end;

  // Store the current state
  OldState := InternalGameState;

  // Move the block
  MoveBlock(pDeltaX, 0);

  // If the state went form locked to falling, trigger the event
  if (OldState = gsLockDown) and (InternalGameState = gsFalling) then
    Execute( OnEnterFallingPhase );
end;

procedure TtetrisGame.RotateClockwise;
var NewOrientation: TPetriminoOrientation;
begin
  // Determine what the next orientation is
  if FCurrent.Orientation = high(TPetriminoOrientation) then
    NewOrientation := low(TPetriminoOrientation)
  else
    NewOrientation := succ(FCurrent.Orientation);

  // Check if the new orientation is possible
  if OrientationOK(NewOrientation) then
  begin
    // Rotate the block on the board
    BlockFromBoard(FCurrent);
    FCurrent.Orientation := NewOrientation;
    BlockToBoard(FCurrent);

    // Notify the GUI about the update
    Execute( FOnMatrixChanged );

    // Check if the block movement resulted in a lock state (hit another block below)
    CheckEnterLockPhase;
  end;
end;

procedure TtetrisGame.MoveLeft;
begin
  MoveHorizontal( -1 )
end;

procedure TtetrisGame.MoveRight;
begin
  MoveHorizontal( +1 )
end;

procedure TtetrisGame.DropBlockDown;
begin
  while CurrentCanMoveDown do
  begin
    IncreaseScore(Level);
    MoveBlock(0, -1);
  end;
  FixateBlock;
end;

function TtetrisGame.PetriminoCount(const pType: TPetriminoType): integer;
begin
  result := FPetriminoCount[pType]
end;

procedure TtetrisGame.Next;
begin
  case InternalGameState of
    gsReady     : begin
                    NextInPipeline;
                    GenerateNextPetrimino;
                  end;
    gsFalling   : MoveVertical;
    gsLockDown  : FixateBlock;
  end;

  // Game ended?
  if InternalGameState = gsEnded then
    Execute( FOnGameEnded );
end;

end.

