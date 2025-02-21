unit UnitWorkWithFiles;

interface

uses Winapi.Windows, System.SysUtils,
    Vcl.Controls, Vcl.Dialogs, System.RegularExpressions;

type
    TArrStr = Array of String;

procedure OpenFileChess();
procedure SaveToFileAs();

implementation

uses UnitMainForm, UnitSetupBoard, UnitReplayAndNotation, UnitTimer, UnitMyMessageBoxes,
    UnitMakeAMove;

procedure DoAfterOpenedGameFromFile(); forward;
procedure ClickListBoxToKillBug(); forward;
function FindRegEx(SInput, StrRegEx: String; StrIfNothingFound: String = '') : TArrStr; forward;

procedure OpenFileChess();
const
    ErrorDuringInputOccured = '�������� ������ ��� �������� �����.' + #10#13 +
                '����������, �������� ���� ������� (.txt) � ' +
                '����������� �������.';

var
    FileInput : TextFile;
    PathToFile, String1, RegEx: String;
    i, j, k: Integer;
    WhiteIsToMoveTemp, IsCorrect, SaidNoSaving: Boolean;

begin
    IsCorrect := True;
    SaidNoSaving := False;

    with FormMain do
    begin
        if not GameIsSaved then
            if MyMessageBoxYesNo('��������� ������?', '�� ������ ��������� ������� ������?' +
            #10#13 + '����� ����� �������� ����� ������� ������ ����� �������.', True) then
                NSaveAsClick(FormMain)
            else
                SaidNoSaving := True;

        if (GameIsSaved or SaidNoSaving or MyMessageBoxYesNo('������� ����� ������?', '�� �������, ��� ������ ������� ����� ������?' + #10#13 +
            '������� ������ ����� �������.', True))
            and OpenDialog1.Execute then
        begin
            PathToFile := OpenDialog1.FileName;

            ResetChessboardToStandart();

            try
                AssignFile(FileInput, PathToFile);
                Reset(FileInput);

                Readln(FileInput, String1);
                RegEx := FindRegEx(String1, '\bGame ended:\s*[01]\b')[0];
                if RegEx <> '' then
                    Game.GameEnded := FindRegEx(RegEx, '[01]')[0] = '1'
                else
                    IsCorrect := False;

                if IsCorrect then
                begin
                    Readln(FileInput, String1);
                    RegEx := FindRegEx(String1, '\bTime remaining white:\s*\d{1,5}\b')[0];
                    if RegEx <> '' then
                    begin
                        Game.TimeRemainingW := StrToInt(FindRegEx(RegEx, '\d+')[0]);
                        ShowTimeOnTimer(True);
                    end
                    else
                        IsCorrect := False;
                end;

                if IsCorrect then
                begin
                    Readln(FileInput, String1);
                    RegEx := FindRegEx(String1, '\bTime remaining black:\s*\d{1,5}\b')[0];
                    if RegEx <> '' then
                    begin
                        Game.TimeRemainingB := StrToInt(FindRegEx(RegEx, '\d+')[0]);
                        ShowTimeOnTimer(False);
                    end
                    else
                        IsCorrect := False;
                end;

                if IsCorrect then
                begin
                    Readln(FileInput, String1);
                    IsCorrect := String1 = 'NOTATION_START';
                end;

                if IsCorrect then
                begin
                    // import of notation
                    WhiteIsToMove := True;
                    Readln(FileInput, String1);
                    repeat
                        if WhiteIsToMove then
                        begin
                            ListBoxNotationW.Items.Add(String1);
                            ListBoxNotationNum.Items.Add(IntToStr(ListBoxNotationW.Count) + '.');
                            CorrectLengthOfScrollboxForNotation();
                        end
                        else
                            ListBoxNotationB.Items.Add(String1);

                        WhiteIsToMove := not WhiteIsToMove;

                        Readln(FileInput, String1);
                    until String1.StartsWith('NOTATION_END', True) or EoF(FileInput);

                    if EoF(FileInput) then
                        IsCorrect := False;
                end;

                if IsCorrect then
                begin
                    // import of boards
                    SetLength(Game.AllBoards, 0);
                    WhiteIsToMoveTemp := True;
                    Readln(FileInput, String1);
                    while (String1 <> 'BOARDS_END') and not EoF(FileInput) and IsCorrect do
                    begin
                        if WhiteIsToMoveTemp then
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
                                    end;
                                end;
                        end;

                        if FindRegEx(String1, '\b([0PKQNBR][01][01]){64}\b')[0] <> '' then
                        begin
                            k := 1;
                            while k < Length(String1) do
                            begin
                                for i := 1 to 8 do
                                    for j := 1 to 8 do
                                    begin
                                        with Game.AllBoards[High(Game.AllBoards)][Ord(not WhiteIsToMoveTemp)][i][j] do
                                        begin
                                            CellFigureName := String1[k];
                                            CellFigureColorIsWhite := String1[k + 1] = '1';
                                            CellFigureHasMoved := String1[k + 2] = '1';
                                        end;
                                        k := k + 3;
                                    end;
                            end;

                            WhiteIsToMoveTemp := not WhiteIsToMoveTemp;
                            Readln(FileInput, String1);
                        end
                        else
                            IsCorrect := False;
                    end;
                    if EoF(FileInput) then
                        IsCorrect := False;
                end;

                if IsCorrect then
                begin
                    Readln(FileInput, String1);
                    RegEx := FindRegEx(String1, '\b[1-8]{4}\b')[0];

                    if RegEx <> '' then
                        LastMove := String1
                    else
                        IsCorrect := False;

                    if IsCorrect then
                    begin
                        DoAfterOpenedGameFromFile();
                        if PageControl1.ActivePageIndex <> 1 then
                            PageControl1.ActivePageIndex := 1;
                    end;

                    CloseFile(FileInput);
                end;
            except
                IsCorrect := False;
            end;



            if not IsCorrect then
            begin
                MyMessageBoxInfo('������', ErrorDuringInputOccured, True);
                ResetChessboardToStandart();
            end;
        end;
    end;
end;

procedure DoAfterOpenedGameFromFile();
begin
    with FormMain do
    begin
        if ListBoxNotationW.Count > ListBoxNotationB.Count then
        begin
            ItemIndexW := ListBoxNotationW.Count - 1;
            ItemIndexB := -1;
        end
        else
        begin
            ItemIndexB := ListBoxNotationB.Count - 1;
            ItemIndexW := -1;
        end;

        ShowReplay();

        if not Game.GameEnded then
        begin
            TimerForTimer.Enabled := True;
            ImagePauseAndStartTimer.Picture := ImagePause.Picture;
            ImagePauseAndStartTimer.Visible := True;
            ItemIndexW := -1;
            ItemIndexB := -1;
            ButtonResign.Enabled := True;
            ButtonDraw.Enabled := True;
        end
        else
        begin
            TimerForTimer.Enabled := False;
            ImagePauseAndStartTimer.Visible := False;
            ButtonResign.Enabled := False;
            ButtonDraw.Enabled := False;
            ButtonReplayClick(FormMain);
        end;

        PanelChoiceOfTransPawnForBlack.Visible := False;
        PanelChoiceOfTransPawnForWhite.Visible := False;
        PanelGameEnded.Visible := False;

        ClickListBoxToKillBug();
    end;
end;

procedure ClickListBoxToKillBug();
var
    CursorClipArea: TRect;
    MousePoint1, MousePoint2: TPoint;

begin
    GetCursorPos(MousePoint1);

    with FormMain do
        with ListBoxNotationW do
        begin
            CursorClipArea.TopLeft := ClientToScreen(ItemRect(ListBoxNotationW.Count - 1).TopLeft);
            CursorClipArea.BottomRight := ClientToScreen(ItemRect(ListBoxNotationW.Count - 1).BottomRight);
        end;

    Winapi.Windows.ClipCursor(@CursorClipArea);

    GetCursorPos(MousePoint2);
    mouse_event(MOUSEEVENTF_LEFTDOWN,MousePoint2.X,MousePoint2.Y,0,0);
    mouse_event(MOUSEEVENTF_LEFTUP,MousePoint2.X,MousePoint2.Y,0,0);

    Winapi.Windows.ClipCursor(nil);
    SetCursorPos(MousePoint1.X, MousePoint1.Y);
end;


procedure SaveToFileAs();
var
    FileOutput : TextFile;
    StrFilePath: String;
    ShouldNotRepeat, TimerGoes: Boolean;
    Point: TPoint;
    i, j ,k, ii: Integer;

begin
    with FormMain do
    begin
        TimerGoes := TimerForTimer.Enabled;
        TimerForTimer.Enabled := False;

        try
            repeat
                ShouldNotRepeat := True;
                SaveDialog1.FileName := 'Chess game ' + DateTimeToStr(Date) + ' ' + TimeToStr(Time).Replace(':', '-', [rfReplaceAll]) + '.txt';

                if SaveDialog1.Execute then
                begin
                    StrFilePath := SaveDialog1.FileName;
                    StrFilePath := FindRegEx(StrFilePath, '.+\.txt', StrFilePath + '.txt')[0];

                    if FileExists(StrFilePath) then
                        if MyMessageBoxYesNo('������������ ����?', '����� ���� ��� ����������.' +
                            #10#13 + '�� ������ ������������ ����? ��� �������� ���������� ��������.', True)
                        then
                            ShouldNotRepeat := True
                        else
                            ShouldNotRepeat := False
                    else
                        ShouldNotRepeat := True;

                    if ShouldNotRepeat then
                    begin
                        AssignFile(FileOutput, StrFilePath);
                        Rewrite(FileOutput);

                        Write(FileOutput, 'Game ended: ' + IntToStr(Ord(Game.GameEnded)) + #10#13);
                        Write(FileOutput, 'Time remaining white: ' + IntToStr(Game.TimeRemainingW) + #10#13);
                        Write(FileOutput, 'Time remaining black: ' + IntToStr(Game.TimeRemainingB) + #10#13);

                        Write(FileOutput, 'NOTATION_START' + #10#13);
                        i := 0;
                        while i < ListBoxNotationW.Count do
                        begin
                            Write(FileOutput, ListBoxNotationW.Items[i] + #10#13);
                            if i < ListBoxNotationB.Count then
                                Write(FileOutput, ListBoxNotationB.Items[i] + #10#13);

                            Inc(i);
                        end;
                        Write(FileOutput, 'NOTATION_END' + #10#13);


                        for k := 0 to High(Game.AllBoards) do
                        begin
                            for ii := 0 to 1 do
                            begin
                                for i := 1 to 8 do
                                    for j := 1 to 8 do
                                        with Game.AllBoards[k][ii][i][j] do
                                            Write(FileOutput, CellFigureName + IntToStr(Ord(CellFigureColorIsWhite)) + IntToStr(Ord(CellFigureHasMoved)));

                                Write(FileOutput, #10#13);
                            end;
                        end;
                        Write(FileOutput, 'BOARDS_END' + #10#13 + LastMove + #10#13);


                        CloseFile(FileOutput);
                        GameIsSaved := True;
                        BalloonHint1.Title := '������';
                        BalloonHint1.Description := '������ ������� ��������� � ����.';
                        Point.X := MultPixels(20);
                        Point.Y := 0;
                        Balloonhint1.ShowHint(ClientToScreen(Point));
                    end;
                end;
            until ShouldNotRepeat;
        except
            MyMessageBoxInfo('������', '�� ������� ������� ���� ��� ������ ������ ��� �������� � ���� ������.');
        end;

        TimerForTimer.Enabled := TimerGoes;
    end;
end;

function FindRegEx(SInput, StrRegEx: String; StrIfNothingFound: String = '') : TArrStr;
var
    ArrStr: TArrStr;
    RegEx: TRegEx;
    MatchCollection: TMatchCollection;
    i: Integer;
begin
    RegEx := TRegEx.Create(StrRegEx);
    MatchCollection := RegEx.Matches(SInput);
    SetLength(ArrStr, MatchCollection.Count);
    for i := 0 to MatchCollection.Count - 1 do
        ArrStr[i] := MatchCollection.Item[i].Value;

    if (Length(ArrStr) < 1) then
        ArrStr := [StrIfNothingFound];
    Result := ArrStr;
end;

end.
