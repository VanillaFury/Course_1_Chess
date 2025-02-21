unit UnitReplayAndNotation;

interface

uses
    Winapi.Windows;

type
    TCellForReplay = Record
        CellFigureName: Char;
        CellFigureColorIsWhite, CellFigureHasMoved: Boolean;
    End;

procedure WriteOneMoveOfGame();
procedure ShowReplay();
procedure CorrectLengthOfScrollboxForNotation();
procedure StartReplayAfterGameFinished();
procedure ReplayGoToEnd();
procedure ReplayGoToStart();
procedure ReplayGoToNext();
procedure ReplayGoToPrev();

var
    ItemIndexW, ItemIndexB: SmallInt;
    BufferFor1Move: String;

implementation

uses UnitMainForm, UnitCreatingFigures, UnitMakeAMove;

procedure ReplayGoToNext();
begin
    with FormMain do
        if ItemIndexW > -1 then
        begin
            if ListBoxNotationB.Count > ItemIndexW then
            begin
                ListBoxNotationW.ItemIndex := -1;
                ListBoxNotationB.ItemIndex := ItemIndexW;
                ItemIndexW := ListBoxNotationW.ItemIndex;
                ItemIndexB := ListBoxNotationB.ItemIndex;

                ShowReplay();
            end;
        end
        else
            if ListBoxNotationW.Count > ItemIndexB + 1 then
            begin
                ListBoxNotationW.ItemIndex := ItemIndexB + 1;
                ListBoxNotationB.ItemIndex := -1;
                ItemIndexW := ListBoxNotationW.ItemIndex;
                ItemIndexB := ListBoxNotationB.ItemIndex;

                ShowReplay();
            end;
end;

procedure ReplayGoToPrev();
begin
    with FormMain do
        if ItemIndexW > -1 then
        begin
            if ItemIndexW > 0 then
            begin
                ListBoxNotationW.ItemIndex := -1;
                ListBoxNotationB.ItemIndex := ItemIndexW - 1;
                ItemIndexW := ListBoxNotationW.ItemIndex;
                ItemIndexB := ListBoxNotationB.ItemIndex;

                ShowReplay();
            end;
        end
        else
        begin
            ListBoxNotationW.ItemIndex := ItemIndexB;
            ListBoxNotationB.ItemIndex := -1;
            ItemIndexW := ListBoxNotationW.ItemIndex;
            ItemIndexB := ListBoxNotationB.ItemIndex;

            ShowReplay();
        end;
end;

procedure ReplayGoToStart();
begin
    with FormMain do
        if ItemIndexW <> 0 then
        begin
            ListBoxNotationW.ItemIndex := 0;
            ListBoxNotationB.ItemIndex := -1;

            ItemIndexW := ListBoxNotationW.ItemIndex;
            ItemIndexB := ListBoxNotationB.ItemIndex;

            ShowReplay();
        end;
end;

procedure ReplayGoToEnd();
begin
    with FormMain do
        if ListBoxNotationW.Count > ListBoxNotationB.Count then
        begin
            if ItemIndexW <> ListBoxNotationW.Count - 1 then
            begin
                ListBoxNotationW.ItemIndex := ListBoxNotationW.Count - 1;
                ListBoxNotationB.ItemIndex := -1;
                ItemIndexW := ListBoxNotationW.ItemIndex;
                ItemIndexB := ListBoxNotationB.ItemIndex;

                ShowReplay();
            end;
        end
        else
        begin
            if ItemIndexB <> ListBoxNotationB.Count - 1 then
            begin
                ListBoxNotationB.ItemIndex := ListBoxNotationB.Count - 1;
                ListBoxNotationW.ItemIndex := -1;
                ItemIndexW := ListBoxNotationW.ItemIndex;
                ItemIndexB := ListBoxNotationB.ItemIndex;

                ShowReplay();
            end;
        end;
end;

procedure WriteOneMoveOfGame();
var
    i, j: Byte;

begin
    if not WhiteIsToMove then
    begin
        SetLength(Game.AllBoards, Length(Game.AllBoards) + 1);

        // ��������� ������
        for i := 1 to 8 do
            for j := 1 to 8 do
            begin
                with Game.AllBoards[High(Game.AllBoards)][1][i][j] do
                begin
                    CellFigureName := '0';
                    CellFigureColorIsWhite := False;
                    CellFigureHasMoved := False;
                end;
            end;
    end;

    for i := 1 to 8 do
        for j := 1 to 8 do
        begin
            with Game.AllBoards[High(Game.AllBoards)][Ord(WhiteIsToMove)][i][j] do
            begin
                CellFigureName := BoardReal[i][j].CellFigureName;
                if CellFigureName <> '0' then
                begin
                    CellFigureColorIsWhite := BoardReal[i][j].CellFigureColorIsWhite;
                    CellFigureHasMoved := ArrOfFigures[BoardReal[i][j].CellFigureIndex].FHasMoved;
                end
                else
                begin
                    CellFigureColorIsWhite := False;
                    CellFigureHasMoved := False;
                end;
            end;
        end;
end;


procedure StartReplayAfterGameFinished();
begin
    with FormMain do
    begin
        PanelGameEnded.Visible := False;
        PanelForReplay.Visible := True;
        ImagePauseAndStartTimer.Visible := False;
        if ListBoxNotationW.Count > ListBoxNotationB.Count then
        begin
            ListBoxNotationW.ItemIndex := ListBoxNotationW.Count - 1;
            ItemIndexW := ListBoxNotationW.ItemIndex;
        end
        else
        begin
            ListBoxNotationB.ItemIndex := ListBoxNotationB.Count - 1;
            ItemIndexB := ListBoxNotationB.ItemIndex;
        end;
    end;
end;

procedure ShowReplay();
var
    BoardTemp: Array [1 .. 8, 1 .. 8] of TCellForReplay;
    i, j, k: Byte;
    EmptySpaceInArrayNotFound: Boolean;
    ColorOfFigure: Char;

begin
    // Copy board
    for i := 1 to 8 do
        for j := 1 to 8 do
        begin
            with Game.AllBoards
              [ItemIndexW + ItemIndexB + 1][Ord(ItemIndexW = -1)][i][j] do
            begin
                BoardTemp[i][j].CellFigureName := CellFigureName;
                BoardTemp[i][j].CellFigureColorIsWhite := CellFigureColorIsWhite;
                BoardTemp[i][j].CellFigureHasMoved := CellFigureHasMoved;
            end;
        end;

    with FormMain do
    begin
    // Delete what should be deleted
        for i := 1 to 8 do
            for j := 1 to 8 do
                if (BoardReal[i][j].CellFigureName <> '0') and
                  ((BoardTemp[i][j].CellFigureName <> BoardReal[i][j]
                  .CellFigureName) or (BoardTemp[i][j].CellFigureColorIsWhite <>
                  BoardReal[i][j].CellFigureColorIsWhite)
                  or (BoardTemp[i][j].CellFigureHasMoved <>
                  ArrOfFigures[BoardReal[i][j].CellFigureIndex].FHasMoved)) then
                begin
                    KillFigureOnCell(i, j, False);
                end;

        // Create what should be created
        for i := 1 to 8 do
            for j := 1 to 8 do
                if (BoardTemp[i][j].CellFigureName <> BoardReal[i][j].CellFigureName)
                then
                begin
                    k := 0;
                    EmptySpaceInArrayNotFound := True;
                    while (k < Length(ArrOfFigures)) and
                      EmptySpaceInArrayNotFound do
                    begin
                        if ArrOfFigures[k] <> nil then
                            Inc(k)
                        else
                            EmptySpaceInArrayNotFound := False;
                    end;

                    if BoardTemp[i][j].CellFigureColorIsWhite then
                        ColorOfFigure := 'W'
                    else
                        ColorOfFigure := 'B';

                    CreateOneFigure(ArrOfFigures[k], k, i, j,
                      BoardTemp[i][j].CellFigureName, ColorOfFigure, BoardTemp[i][j].CellFigureHasMoved);
                end;
    end;
end;

procedure CorrectLengthOfScrollboxForNotation();
var
    Rect: TRect;

begin
    with FormMain do
        begin
        Rect := ListBoxNotationW.ItemRect(ListBoxNotationW.Count - 1);
        if Rect.Top + Rect.Height > ListBoxNotationW.Top + ListBoxNotationW.Height then
        begin
            ListBoxNotationW.Height := ListBoxNotationW.Height + 50;
            ListBoxNotationB.Height := ListBoxNotationB.Height + 50;
            ListBoxNotationNum.Height := ListBoxNotationNum.Height + 50;
        end;
    end;
end;

end.
