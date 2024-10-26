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

unit gameform;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  SysUtils,
  FileUtil,
  Forms,
  Controls,
  Graphics,
  Dialogs,
  ExtCtrls,
  Grids,
  StdCtrls,
  Buttons,
  Engine,
  Types,
  LCLType,
  ShellAPI,
  MMSystem;

type
  { TForm1 }
  TForm1 = class(TForm)
    dgtetris: TDrawGrid;
    ilMinos: TImageList;
    Image1: TImage;
    ImageList1: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    pnScore1: TPanel;
    pnScore2: TPanel;
    Retro: TLabel;
    Panel3: TPanel;
    Panel2: TPanel;
    pbPipeline: TPaintBox;
    tmrPhase: TTimer;

    procedure dgtetrisDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Label2Click(Sender: TObject);
    procedure pbPipelinePaint(Sender: TObject);
    procedure tmrEnded(Sender: TObject);

  private
    FGame: TtetrisGame;
    FFallFast: boolean;
    FPreviousMinoPos: TPoint;

    procedure StartGame;
    procedure RepaintBoard      ( pGame: TtetrisGame );
    procedure PipelineChanged   ( pGame: TtetrisGame );
    procedure EnterFallingPhase ( pGame: TtetrisGame );
    procedure EnterLockPhase    ( pGame: TtetrisGame );
    procedure EndGame           ( pGame: TtetrisGame );
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }
procedure TForm1.FormDestroy(Sender: TObject);
begin
  // Membersihkan area yang telah ada
  FGame.Free;
end;

procedure TForm1.dgtetrisDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect; aState: TGridDrawState);
var clr: TColor;
    col, row: integer;
    idx: integer;
begin
  // Memastikan bahwa game berjalan jika tidak maka akan keluar
  if not assigned(FGame) then exit;

  // Melakukan translasi koordinat pada grid sel ke koordinat matrix game
  col := aCol + 1;
  row := dgtetris.RowCount - aRow;
  if FGame.Mino[col,row].CellState <> pssOpen then
    begin
      idx := ord(FGame.Mino[col,row].MinoType);
      ilMinos.Draw(dgtetris.Canvas, aRect.Left, aRect.Top, idx);
    end
  else
    begin
      clr := clBlack;
      dgtetris.Canvas.Brush.Color := clr;
      dgtetris.Canvas.FillRect(aRect);
    end;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // Menetapkan key yang akan digunakan saat game berjalan
  if assigned(FGame) then
    begin
      if Key = VK_LEFT then
        FGame.MoveLeft;
      if Key = VK_RIGHT then
        FGame.MoveRight;
      if Key = VK_UP then
        FGame.RotateClockwise;
      if Key = VK_DOWN then
      begin
        FFallFast := true;
        if FGAme.GameState = gsFalling then
          tmrEnded(tmrPhase);
      end;
      Key := 0
    end
  else
    // Menambahkan fungsi tekan spasi untuk memulai game
    if Key = VK_SPACE then
      StartGame;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // Menambahkan fungsi jika tombol panah bawah ditekan maka dia akan mematikan fallfast
  if Key = VK_DOWN then
    FFallFast := false;
end;

procedure TForm1.Label2Click(Sender: TObject);
begin
    // Fungsi open url untuk menuju repository
    ShellExecute(0, 'open', 'https://github.com/shiwildy/RetroTetris', nil, nil, SW_SHOWNORMAL);
end;

procedure TForm1.pbPipelinePaint(Sender: TObject);
var pb     : TPaintBox;
    i      : integer;
    TopLeft: TPoint;
    WorldXY: TPoint;
begin
  // Mengambar Background pada canvas
  pb := Sender as TPaintBox;
  pb.Canvas.Brush.Color := clBlack;
  pb.Canvas.FillRect(0,0, pb.Width,pb.Height);

  // Melakukan validasi apakah game berjalan atau tidak
  if assigned(FGame) then
  begin
    // Menghitung pojok kiri atas apakah minos pertamanya adalah 0,0 dalam paintbox
    topleft.y := pbPipeline.Height div 2 - 24;
    case FGame.PipeLine.PetriminoType of
      pmtO: topleft.x := pbPipeline.Width div 2 - 48;
      pmtI: topleft   := point(pbPipeline.Width div 2 - 48, pbPipeline.Height div 2 - 36);
    else
      topleft.x := pbPipeline.Width div 2 - 36;
    end;

    // Mengambar sisa 4 minos yang ada pada petrimino
    for i := 0 to 3 do
    begin
      WorldXY := Point( TopLeft.X + FGame.PipeLine.Position(i).x * 24,
                        TopLeft.Y - FGame.PipeLine.Position(i).y * 24);
      ilMinos.Draw(pb.Canvas, WorldXY.x, WorldXY.y, ord(FGame.PipeLine.PetriminoType));
    end;
  end;
end;

procedure TForm1.EnterFallingPhase(pGame: TtetrisGame);
var NewInt: integer;
begin
  // Mematikan semua kemungkinan pada konfigurasi sebelumnya
  // untuk memastikan permainan telah menjalankan penurunan baru
  tmrPhase.Enabled := false;

  // Melakukan perhitungan kecepatan petriminonya akan jatuh
  // Untuk perhitungan ini bergantung dari level, semakin tinggi level semakin cepat juga petriminonya turun
  NewInt := 500 - ( (pGame.Level-1) * 40 );
  if FFallFast then
    NewInt := NewInt div 10;
  if NewInt < 5 then NewInt := 5;
  tmrPhase.Interval := NewInt;

  // Memulai timer
  tmrPhase.Enabled := true;
end;

procedure TForm1.EnterLockPhase(pGame: TtetrisGame);
begin
  // Selama game dalam mode lockphase maka diakan melakukan setting interval saat pemain memindahkann block
  tmrPhase.Enabled := false;
  tmrPhase.Interval := 250;
  tmrPhase.Enabled := true;
end;

procedure TForm1.tmrEnded(Sender: TObject);
begin
  // Mematikan timer dan biarkan game melanjutkan aksi selanjutnya
  (Sender as TTimer).Enabled := false;
  FGame.Next;
end;

procedure TForm1.StartGame;
begin
  if assigned(FGame) then exit;

  // Memastikan drawgrid tidak memiliki fokus
  self.SetFocus;

  // Mengacak petrimino yang akan muncul
  Randomize;

  // Play Backsound
  mciSendString('open "sound/backsound.mp3" type mpegvideo alias BackSound', nil, 0, 0);
  mciSendString('play BackSound repeat', nil, 0, 0);

  // Memulai game baru
  FGame := TtetrisGame.Create;
  FGame.OnMatrixChanged     := @RepaintBoard;
  FGame.OnPipelineChanged   := @PipelineChanged;
  FGame.OnEnterFallingPhase := @EnterFallingPhase;
  FGame.OnEnterLockPhase    := @EnterLockPhase;
  FGame.OnEndGame           := @EndGame;
  FGame.Next;

end;

procedure TForm1.RepaintBoard(pGame: TtetrisGame);
begin
  dgtetris.Repaint;
  pnScore2.Caption := IntToStr(pGame.Level);
  pnScore1.Caption := IntToStr(pGame.Score);
end;

procedure TForm1.PipelineChanged(pGame: TtetrisGame);
begin

  pbPipeline.Repaint;
end;

procedure TForm1.EndGame(pGame: TtetrisGame);
begin
  // Hentikan backsound jika game sudah berakhir
  mciSendString('stop BackSound', nil, 0, 0);

  // Play LoseSong
  mciSendString('open "sound/lose.mp3" type mpegvideo alias LoseHaha', nil, 0, 0);
  mciSendString('play LoseHaha', nil, 0, 0);

  tmrPhase.Enabled := false;
  pGame.Free;
  FGame := nil;
  Application.MessageBox('Yahh, anda kalah coba lagi yok, jangan nangis', 'Game Over', MB_OK or MB_ICONINFORMATION);

  // Menghapus semua elemen yang visible
  dgtetris.Repaint;
  pbPipeline.Repaint;
end;
end.
