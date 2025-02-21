unit UnitCheckMoveIsLegal;

interface

uses
    System.SysUtils, Vcl.Dialogs, UnitCreatingFigures, UnitSetupBoard;

function CheckMoveLegal(Figure: TFigure;
  PosX, PosY: Byte): Boolean;
function CheckMoveLegalPhysically(Board: TBoard; Figure: TFigure;
  PosX, PosY: Byte): Boolean;

implementation

uses UnitMainForm, UnitCheckChecksMatesAndStalemates, UnitMakeAMove, UnitMyMessageBoxes;

function CheckMoveLegalBecauseOfKillingKing(Figure: TFigure;
  NextX, NextY: Byte): Boolean; forward;
function CheckMovePawnLegalPhysically(Board: TBoard;
  Figure: TFigure; PosX, PosY: Byte; XRelat, YRelat: SmallInt): Boolean; forward;
function CheckMoveQueenLegalPhysically(Board: TBoard;
  Figure: TFigure; PosX, PosY: Byte; XRelat, YRelat: SmallInt): Boolean; forward;
function CheckMoveRookLegalPhysically(Board: TBoard;
  Figure: TFigure; PosX, PosY: Byte; XRelat, YRelat: SmallInt): Boolean; forward;
function CheckMoveBishopLegalPhysically(Board: TBoard;
  Figure: TFigure; PosX, PosY: Byte; XRelat, YRelat: SmallInt): Boolean; forward;
function CheckMoveKnightLegalPhysically(Board: TBoard;
  Figure: TFigure; PosX, PosY: Byte; XRelat, YRelat: SmallInt): Boolean; forward;
function CheckMoveKingLegalPhysically(Board: TBoard;
  Figure: TFigure; PosX, PosY: Byte; XRelat, YRelat: SmallInt): Boolean; forward;

function CheckMoveLegal(Figure: TFigure;
  PosX, PosY: Byte): Boolean;
begin
    with Figure do
        Result := (FIsWhite = WhiteIsToMove) and (PosX < 9) and (PosX > 0) and
          (PosY < 9) and (PosY > 0) and
          ((PosX <> FPosOnBoardX) or (PosY <> FPosOnBoardY)) and
          CheckMoveLegalPhysically(BoardReal, Figure, PosX, PosY) and
          CheckMoveLegalBecauseOfKillingKing(Figure, PosX, PosY);
end;

function CheckMoveLegalBecauseOfKillingKing(Figure: TFigure;
  NextX, NextY: Byte): Boolean;
var
    BoardTemp: TBoard;
    IsNotMate: Boolean;
    King: TFigure;

begin
    BoardTemp := BoardReal;
    MoveFigureToCell(BoardTemp, Figure, NextX, NextY, False);

    King := FindKing(Figure.FIsWhite);

    with King do
        if Figure = King then
            IsNotMate := CheckIfCellIsNotAttacked(BoardTemp, NextX, NextY,
              not FIsWhite)
        else
            IsNotMate := CheckIfCellIsNotAttacked(BoardTemp, FPosOnBoardX,
              FPosOnBoardY, not FIsWhite);

    Result := IsNotMate;
end;

function CheckMovePawnLegalPhysically(Board: TBoard;
  Figure: TFigure; PosX, PosY: Byte; XRelat, YRelat: SmallInt): Boolean;
const
    AllowedMovesPawn: Array [0 .. 3] of Array [0 .. 1] of SmallInt = ((0, 1),
      (0, 2), (1, 1), (-1, 1));

var
    IsLegal, LoopShouldGo: Boolean;
    i: Byte;
    CorrectorForColor: SmallInt;

begin
    IsLegal := False;
    LoopShouldGo := True;
    i := 0;

    with Figure do
    begin
        if FIsWhite then
            CorrectorForColor := 1
        else
            CorrectorForColor := -1;

        while (i < Length(AllowedMovesPawn)) and LoopShouldGo do
        begin
            if ((XRelat = AllowedMovesPawn[i][0] * CorrectorForColor) and
              (YRelat = AllowedMovesPawn[i][1] * CorrectorForColor)) then
            begin
                LoopShouldGo := False;

                if (i < 2) then
                begin
                    if (Board[PosX][PosY].CellFigureName = '0') then
                        if (i = 1) then
                        begin
                            IsLegal := Not FHasMoved and
                              (Board[PosX][PosY - CorrectorForColor]
                              .CellFigureName = '0');
                        end
                        else
                            IsLegal := True;
                end
                else if Board[PosX][PosY].CellFigureName <> '0' then
                    IsLegal := Board[PosX][PosY]
                      .CellFigureColorIsWhite xor FIsWhite
                else
                begin
                    if (((PosY = 6) and FIsWhite) or
                      ((PosY = 3) and not FIsWhite)) and
                      (StrToInt(LastMove[3]) = PosX) and
                      (StrToInt(LastMove[4]) = PosY - CorrectorForColor) and
                      (Board[StrToInt(LastMove[3])][StrToInt(LastMove[4])
                      ].CellFigureName = 'P') then
                    begin
                        IsLegal := True;
                        NowIsTakingOnAisle := True;
                    end;
                end;
            end;
            Inc(i);
        end;
    end;

    Result := IsLegal;
end;

function CheckMoveQueenLegalPhysically(Board: TBoard;
  Figure: TFigure; PosX, PosY: Byte; XRelat, YRelat: SmallInt): Boolean;
begin
    Result := CheckMoveRookLegalPhysically(Board, Figure, PosX, PosY, XRelat,
      YRelat) or CheckMoveBishopLegalPhysically(Board, Figure, PosX, PosY,
      XRelat, YRelat);
end;

function CheckMoveRookLegalPhysically(Board: TBoard;
  Figure: TFigure; PosX, PosY: Byte; XRelat, YRelat: SmallInt): Boolean;
var
    IsLegal, LoopShouldGo: Boolean;
    i: Byte;
    Incr: ShortInt;

begin
    IsLegal := (XRelat = 0) or (YRelat = 0);

    if IsLegal then
        IsLegal := (Board[PosX][PosY].CellFigureName = '0') or
          (Board[PosX][PosY].CellFigureColorIsWhite = not Figure.FIsWhite);

    with Figure do
        if IsLegal then
        begin
            if XRelat = 0 then
            begin
                Incr := Ord(YRelat > 0) * 2 - 1;
                i := FPosOnBoardY + Incr;
            end
            else
            begin
                Incr := Ord(XRelat > 0) * 2 - 1;
                i := FPosOnBoardX + Incr;
            end;

            LoopShouldGo := True;
            while IsLegal and (i < 9) and (i > 0) and LoopShouldGo do
            begin
                if XRelat = 0 then
                    if i <> PosY then
                        IsLegal := Board[FPosOnBoardX][i].CellFigureName = '0'
                    else
                        LoopShouldGo := False
                else if i <> PosX then
                    IsLegal := Board[i][FPosOnBoardY].CellFigureName = '0'
                else
                    LoopShouldGo := False;

                i := i + Incr;
            end;

        end;
    Result := IsLegal;
end;

function CheckMoveBishopLegalPhysically(Board: TBoard;
  Figure: TFigure; PosX, PosY: Byte; XRelat, YRelat: SmallInt): Boolean;
var
    IsLegal, LoopShouldGo: Boolean;
    i, j: Byte;
    IncrX, IncrY: ShortInt;

begin
    IsLegal := Abs(XRelat) = Abs(YRelat);

    if IsLegal then
        IsLegal := (Board[PosX][PosY].CellFigureName = '0') or
          (Board[PosX][PosY].CellFigureColorIsWhite = not Figure.FIsWhite);

    with Figure do
        if IsLegal then
        begin
            IncrX := Ord(XRelat > 0) * 2 - 1;
            IncrY := Ord(YRelat > 0) * 2 - 1;

            i := FPosOnBoardX + IncrX;
            j := FPosOnBoardY + IncrY;
            LoopShouldGo := True;
            while IsLegal and (i < 9) and (i > 0) and (j < 9) and (j > 0) and
              LoopShouldGo do
            begin
                if i <> PosX then
                    IsLegal := Board[i][j].CellFigureName = '0'
                else
                    LoopShouldGo := False;

                i := i + IncrX;
                j := j + IncrY;
            end;
        end;

    Result := IsLegal;
end;

function CheckMoveKnightLegalPhysically(Board: TBoard;
  Figure: TFigure; PosX, PosY: Byte; XRelat, YRelat: SmallInt): Boolean;
var
    IsLegal: Boolean;

begin
    IsLegal := Abs(XRelat) + Abs(YRelat) = 3;

    if IsLegal then
        IsLegal := (Board[PosX][PosY].CellFigureName = '0') or
          (Board[PosX][PosY].CellFigureColorIsWhite = not Figure.FIsWhite);

    if IsLegal then
        IsLegal := (Abs(XRelat) = 2) or (Abs(YRelat) = 2);

    Result := IsLegal;
end;

function CheckMoveKingLegalPhysically(Board: TBoard;
  Figure: TFigure; PosX, PosY: Byte; XRelat, YRelat: SmallInt): Boolean;
var
    IsLegal: Boolean;
    Rook: TFigure;
    ColNum: Byte;
    BoardTemp: TBoard;

begin
    IsLegal := ((Abs(XRelat) < 2) and (Abs(YRelat) < 2)) or
      ((Abs(XRelat) = 2) and (YRelat = 0));

    if IsLegal then
        IsLegal := (Board[PosX][PosY].CellFigureName = '0') or
          (Board[PosX][PosY].CellFigureColorIsWhite = not Figure.FIsWhite);

    if IsLegal and (Abs(XRelat) = 2) then
    begin
        IsLegal := (Board[PosX][PosY].CellFigureName = '0');

        if XRelat > 0 then
            ColNum := 8
        else
            ColNum := 1;

        if IsLegal and (not Figure.FHasMoved) and
          (Board[ColNum][8 - Ord(Figure.FIsWhite) * 7].CellFigureName = 'R')
        then
        begin
            Rook := ArrOfFigures[Board[ColNum][8 - Ord(Figure.FIsWhite) * 7]
              .CellFigureIndex];
            if (Rook.FIsWhite = Figure.FIsWhite) and (not Rook.FHasMoved) then
            begin
                BoardTemp := Board;
                with Figure do
                    BoardTemp[FPosOnBoardX][FPosOnBoardY].CellFigureName := '0';
                // remove king in Temp Board

                if ColNum = 8 then
                    if (Board[6][8 - Ord(Figure.FIsWhite) * 7]
                      .CellFigureName = '0') and
                      CheckIfCellIsNotAttacked(BoardTemp, 6,
                      8 - Ord(Figure.FIsWhite) * 7, not Figure.FIsWhite) and
                      CheckIfCellIsNotAttacked(BoardTemp, 7,
                      8 - Ord(Figure.FIsWhite) * 7, not Figure.FIsWhite) and not NowCheck
                    then
                        NowIsCastling := True
                    else
                        IsLegal := False
                else if (Board[2][8 - Ord(Figure.FIsWhite) * 7]
                  .CellFigureName = '0') and
                  (Board[4][8 - Ord(Figure.FIsWhite) * 7].CellFigureName = '0')
                  and CheckIfCellIsNotAttacked(BoardTemp, 4,
                  8 - Ord(Figure.FIsWhite) * 7, not Figure.FIsWhite) and
                  CheckIfCellIsNotAttacked(BoardTemp, 3,
                  8 - Ord(Figure.FIsWhite) * 7, not Figure.FIsWhite) and not NowCheck
                then
                    NowIsCastling := True
                else
                    IsLegal := False
            end
            else
                IsLegal := False;
        end
        else
            IsLegal := False;
    end;

    Result := IsLegal;
end;

function CheckMoveLegalPhysically(Board: TBoard; Figure: TFigure;
  PosX, PosY: Byte): Boolean;
var
    IsLegal: Boolean;
    XRelat, YRelat: SmallInt;

begin
    with Figure do
    begin
        if FPsevdoKilled then
        begin
            IsLegal := False;
            FPsevdoKilled := False;
        end
        else
        begin
            XRelat := PosX - FPosOnBoardX;
            YRelat := PosY - FPosOnBoardY;

            case FFigureType of
                'P':
                    IsLegal := CheckMovePawnLegalPhysically(Board, Figure, PosX,
                      PosY, XRelat, YRelat);
                'Q':
                    IsLegal := CheckMoveQueenLegalPhysically(Board, Figure,
                      PosX, PosY, XRelat, YRelat);
                'R':
                    IsLegal := CheckMoveRookLegalPhysically(Board, Figure, PosX,
                      PosY, XRelat, YRelat);
                'B':
                    IsLegal := CheckMoveBishopLegalPhysically(Board, Figure,
                      PosX, PosY, XRelat, YRelat);
                'N':
                    IsLegal := CheckMoveKnightLegalPhysically(Board, Figure,
                      PosX, PosY, XRelat, YRelat);
                'K':
                    IsLegal := CheckMoveKingLegalPhysically(Board, Figure, PosX,
                      PosY, XRelat, YRelat);
            else
                begin
                    MyMessageBoxInfo('������', '������ � ��������� ��������� ������.', True);
                    IsLegal := False;
                end;
            end;
        end;
    end;

    Result := IsLegal;
end;

end.
