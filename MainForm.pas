unit MainForm;

{$mode objfpc}{$h+}

interface

uses
  SysUtils, Classes, Math, Graphics, Controls, Forms, Dialogs, ExtCtrls, Menus,
  StdCtrls, Buttons, Grids, Spin, ActnList, typinfo, types, DrawComponents,
  FileUtil, Clipbrd, ExtDlgs, fpjson, BGRABitmap, BGRABitmapTypes, Properties,
  Drawable, Utils, Transformations, Tools, History, Loaders, GDExport;

type
  { TGreyDrawForm }

  TGreyDrawForm = class(TForm)
    DeleteButton: TSpeedButton;
    Palette: TDrawGrid;
    UndoButton: TSpeedButton;
    RedoButton: TSpeedButton;
    Sep1: TMenuItem;
    CutAction: TMenuItem;
    CopyAction: TMenuItem;
    DeleteAction: TMenuItem;
    Sep2: TMenuItem;
    RedoAction: TMenuItem;
    UndoAction: TMenuItem;
    PasteAction: TMenuItem;
    CutButton: TSpeedButton;
    CopyButton: TSpeedButton;
    PasteButton: TSpeedButton;
    RaiseButton: TSpeedButton;
    SinkButton: TSpeedButton;
    SinkBottomButton: TSpeedButton;
    RaiseTopButton: TSpeedButton;
    SaveItem: TMenuItem;
    OpenItem: TMenuItem;
    NewItem: TMenuItem;
    NormalScaleAction: TAction;
    MinusAction: TAction;
    EscapeAction: TAction;
    FODialog: TOpenDialog;
    PlusAction: TAction;
    FormActionList: TActionList;
    BgDlg: TColorDialog;
    BdDlg: TColorDialog;
    FSDialog: TSaveDialog;
    SMinusBtn: TSpeedButton;
    NewFileButton: TSpeedButton;
    OpenFileButton: TSpeedButton;
    SaveFileButton: TSpeedButton;
    SPlusBtn: TSpeedButton;
    SNormalBtn: TSpeedButton;
    stub: TPanel;
    HScrollBar: TScrollBar;
    PropPanel: TPanel;
    Shape1: TShape;
    Shape2: TShape;
    VScrollBar: TScrollBar;
    ToolPropsPanel: TPanel;
    ToolsPanel: TPanel;
    PropsPanel: TPanel;
    ColorsPanel: TPanel;
    MainMenu1: TMainMenu;
    FileMenu: TMenuItem;
    EditMenu: TMenuItem;
    HelpMenu: TMenuItem;
    ExitItem: TMenuItem;
    AboutItem: TMenuItem;
    BrushColorPanel: TPanel;
    PenColorPanel: TPanel;
    ViewPort: TPaintBox;
    MenuItem1: TMenuItem;
    ExportItem: TMenuItem;
    ExportDalog: TSaveDialog;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    procedure AboutItemClick(Sender: TObject);
    procedure ActionExecute(Sender: TObject);
    procedure BrushColorPanelClick(Sender: TObject);
    procedure CopyActionClick(Sender: TObject);
    procedure CutActionClick(Sender: TObject);
    procedure DeleteActionClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure PaletteDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure PaletteMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure NewFileButtonClick(Sender: TObject);
    procedure PasteActionClick(Sender: TObject);
    procedure ExitItemClick(Sender: TObject);
    procedure OpenFileButtonClick(Sender: TObject);
    procedure PenColorPanelClick(Sender: TObject);
    procedure RaiseButtonClick(Sender: TObject);
    procedure RaiseTopButtonClick(Sender: TObject);
    procedure RedoActionClick(Sender: TObject);
    procedure SaveFileButtonClick(Sender: TObject);
    procedure SinkBottomButtonClick(Sender: TObject);
    procedure SinkButtonClick(Sender: TObject);
    procedure SMinusBtnClick(Sender: TObject);
    procedure SNormalBtnClick(Sender: TObject);
    procedure SPlusBtnClick(Sender: TObject);
    procedure ToolButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure UndoActionClick(Sender: TObject);
    procedure ViewPortMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ViewPortMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ViewPortMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ViewPortMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure ViewPortPaint(Sender: TObject);
    procedure ViewPortResize(Sender: TObject);
    procedure CreateToolButtons;
    procedure SetScrollRect;
    procedure SetScale(AScale: float);
    procedure SetExportFormats;
    procedure SetSaveFormats;
    function SaveAction: Integer;
    function CanBeClosed: Boolean;
    procedure ToggleChangeTag(AChanged: Boolean);
    procedure ExportItemClick(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure HScrollBarChange(Sender: TObject);
    procedure VScrollBarChange(Sender: TObject);
  end;

const
  ChangesTag = '•';

var
  GreyDrawForm: TGreyDrawForm;
  FirstBuffer, SecondBuffer: TBGRABitmap;
  FormatIndex: Integer;
  HasUnsavedChanges: Boolean;

implementation

{$R *.lfm}

{ TGreyDrawForm }

procedure TGreyDrawForm.AboutItemClick(Sender: TObject);
begin
  MessageDlg('Савва Суренков, Б8103а(1)', mtInformation, [mbClose], 0);
end;

procedure TGreyDrawForm.ActionExecute(Sender: TObject);
begin
  case (Sender as TAction).Name of
    'EscapeAction': FigureClosed := True;
    'PlusAction': SPlusBtn.Click;
    'MinusAction': SMinusBtn.Click;
    'NormalScaleAction': SNormalBtn.Click;
  end;
end;

procedure TGreyDrawForm.BrushColorPanelClick(Sender: TObject);
begin
  if BgDlg.Execute then
  begin
    BrushColorPanel.Color := BgDlg.Color;
    TBrushProperty.SetBrushColor(BgDlg.Color);
    FigureClosed := True;
  end;
end;

procedure TGreyDrawForm.CopyActionClick(Sender: TObject);
var
  i: Integer;
  j: TJSONObject;
begin
  j := TJSONObject.Create;
  for i := 0 to High(FiguresList) do
    if FiguresList[i].Selected then
      j.Add(FiguresList[i].CreateUUID, TGreyDrawFormat.SerializeToJSONData(
        FiguresList[i]));
  Clipboard.AsText := j.FormatJSON();
  j.Destroy;
end;

procedure TGreyDrawForm.CutActionClick(Sender: TObject);
begin
  Self.CopyActionClick(Sender);
  Self.DeleteActionClick(Sender);
  AnchorsList.Clear;
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.DeleteActionClick(Sender: TObject);
var
  i: Integer = 0;
  j: Integer;
begin
  while i <= High(FiguresList) do
  begin
    if FiguresList[i].Selected then
    begin
      FiguresList[i].Free;
      for j := i + 1 to High(FiguresList) do
        FiguresList[j - 1] := FiguresList[j];
      SetLength(FiguresList, Length(FiguresList) - 1);
    end
    else
      Inc(i);
  end;
  AnchorsList.Clear;
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := CanBeClosed;
end;

procedure TGreyDrawForm.PaletteDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
begin
  with Sender as TDrawGrid do
  begin
    case aRow of
      0: Canvas.Brush.Color := clRed - aCol * 4;
      1: Canvas.Brush.Color := clBlue + aCol * 4;
      2: Canvas.Brush.Color := clGreen + aCol * 4;
      3: Canvas.Brush.Color := clLime + aCol * 4;
      4: Canvas.Brush.Color := clBlack + TColor($040404) * ACol;
    end;
    Canvas.FillRect(aRect);
    Canvas.Brush.Color := clWhite;
  end;
end;

procedure TGreyDrawForm.PaletteMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  with Sender as TDrawGrid do
    case Button of
      mbLeft:
      begin
        TBrushProperty.SetBrushColor(Canvas.Pixels[X, Y]);
        BrushColorPanel.Color := Canvas.Pixels[X, Y];
      end;
      mbRight:
      begin
        TPenProperty.SetPenColor(Canvas.Pixels[X, Y]);
        PenColorPanel.Color := Canvas.Pixels[X, Y];
      end;
    end;
end;

procedure TGreyDrawForm.NewFileButtonClick(Sender: TObject);
var
  i: Integer;
  F: Boolean = True;
begin
  if HasUnsavedChanges and (MessageDlg(
    'Вы хотите отбросить имеющиеся изменения и создать новый файл?',
    mtWarning, mbYesNo, 0) <> mrYes) then
    F := False;
  if F then
  begin
    for i := 0 to High(FiguresList) do
      FiguresList[i].Destroy;
    SetLength(FiguresList, 0);
    HistoryClear;
    FileName := 'Untitled';
    ViewPort.Invalidate;
    Self.ToggleChangeTag(True);
  end;
end;

procedure TGreyDrawForm.PasteActionClick(Sender: TObject);
begin
  TGreyDrawFormat.LoadFromString(Clipboard.AsText, False);
end;

procedure TGreyDrawForm.ExitItemClick(Sender: TObject);
begin
  self.Close;
end;

procedure TGreyDrawForm.HScrollBarChange(Sender: TObject);
begin
  Offset.x := -HScrollBar.Position;
  //Self.SetScrollRect;
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.VScrollBarChange(Sender: TObject);
begin
  Offset.y := -VScrollBar.Position;
  //Self.SetScrollRect;
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.OpenFileButtonClick(Sender: TObject);
var
  i: Integer;
begin
  if FODialog.Execute then
  begin
    FileName := FODialog.FileName;
    FormatIndex := FODialog.FilterIndex - 1;
    Self.ToggleChangeTag(False);
      if FormatList[FormatIndex].TestLoadFile(FileName) then
        FormatList[FormatIndex].LoadFromFile(FileName);
    HistoryClear;
  end;
end;

procedure TGreyDrawForm.PenColorPanelClick(Sender: TObject);
begin
  if BdDlg.Execute then
  begin
    PenColorPanel.Color := BdDlg.Color;
    TPenProperty.SetPenColor(BdDlg.Color);
    FigureClosed := True;
  end;
end;

procedure TGreyDrawForm.RaiseButtonClick(Sender: TObject);
var
  i: Integer;
  P: TFigure;
begin
  for i := 0 to High(FiguresList) do
    if FiguresList[i].Selected and (FiguresList[i] <>
      FiguresList[High(FiguresList)]) then
    begin
      P := FiguresList[i + 1];
      FiguresList[i + 1] := FiguresList[i];
      FiguresList[i] := P;
    end;
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.RaiseTopButtonClick(Sender: TObject);
var
  i: Integer = 0;
  j, k: Integer;
begin
  for i := 0 to High(FiguresList) do
    if FiguresList[i].Selected then
      Inc(k);
  if k < High(FiguresList) then
    while i < High(FiguresList) do
    begin
      if FiguresList[i].Selected then
      begin
        SetLength(FiguresList, Length(FiguresList) + 1);
        FiguresList[High(FiguresList)] := FiguresList[i];
        for j := i + 1 to High(FiguresList) do
          FiguresList[j - 1] := FiguresList[j];
        SetLength(FiguresList, Length(FiguresList) - 1);
      end
      else
        Inc(i);
    end;
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.RedoActionClick(Sender: TObject);
begin
  TGreyDrawFormat.LoadFromString(HistoryStepForward, True);
  AnchorsList.Clear;
end;

procedure TGreyDrawForm.SaveFileButtonClick(Sender: TObject);
begin
  SaveAction;
end;

procedure TGreyDrawForm.SinkBottomButtonClick(Sender: TObject);
var
  i, j: Integer;
begin
  i := High(FiguresList);
  while i > 0 do
  begin
    if FiguresList[i].Selected then
    begin
      SetLength(FiguresList, Length(FiguresList) + 1);
      for j := High(FiguresList) - 1 downto 0 do
        FiguresList[j + 1] := FiguresList[j];
      FiguresList[0] := FiguresList[i + 1];
      for j := i + 2 to High(FiguresList) do
        FiguresList[j - 1] := FiguresList[j];
      SetLength(FiguresList, Length(FiguresList) - 1);
    end
    else
      Dec(i);
  end;
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.SinkButtonClick(Sender: TObject);
var
  i: Integer;
  P: TFigure;
begin
  for i := High(FiguresList) downto 0 do
    if FiguresList[i].Selected and (FiguresList[i] <> FiguresList[0]) then
    begin
      P := FiguresList[i - 1];
      FiguresList[i - 1] := FiguresList[i];
      FiguresList[i] := P;
    end;
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.SMinusBtnClick(Sender: TObject);
var
  A, B: TPointF;
begin
  B := WorldToScreen(ViewPort.Width, ViewPort.Height);
  Self.SetScale(Scaling / 1.3);
  A := WorldToScreen(ViewPort.Width, ViewPort.Height);
  try
    Offset.x += round(B.x - A.x) div 2;
    Offset.y += round(B.y - A.y) div 2;
  except

  end;
  SetScrollRect;
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.SNormalBtnClick(Sender: TObject);
var
  N: TPointF;
  c: float;
  R: TRect;
begin
  R := ScrollRect;
  Offset.x := -R.Left;
  Offset.y := -R.Top;
  N.x := ViewPort.Height / abs(R.Bottom - R.Top);
  N.y := ViewPort.Width / abs(R.Right - R.Left);
  c := min(N.x, N.y);
  Self.SetScale(c);
  Self.SetScrollRect;
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.SPlusBtnClick(Sender: TObject);
var
  A, B: TPointF;
begin
  A := WorldToScreen(ViewPort.Width, ViewPort.Height);
  Self.SetScale(Scaling * 1.3);
  B := WorldToScreen(ViewPort.Width, ViewPort.Height);
  try
    Offset.x -= round(B.x - A.x) div 2;
    Offset.y -= round(B.y - A.y) div 2;
  except

  end;
  Self.SetScrollRect;
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.ToolButtonClick(Sender: TObject);
var
  i: Integer;
begin
  FigureClosed := True;
  if CurrentTool <> (Sender as TToolButton).Tool then
  begin
    CurrentTool := (Sender as TToolButton).Tool;
    for i := PropPanel.ControlCount - 1 downto 0 do
      PropPanel.Controls[i].Free;
    CurrentTool.CreateControls(TWinControl(PropPanel));
  end;
end;

procedure TGreyDrawForm.FormCreate(Sender: TObject);
begin
  FirstBuffer := TBGRABitmap.Create(ClientWidth, ClientHeight, BGRAWhite);
  ValidEvent := @ViewPort.Invalidate;
  ChangeEvent := @ToggleChangeTag;
  Self.CreateToolButtons;
  Self.SetExportFormats;
  CurrentTool := TSelectTool;
  Self.SetScrollRect;
  GPanel := PropPanel;
  ViewPortCenter := ScreenToWorld(ViewPort.Width div 2, ViewPort.Height div 2);
  Self.DoubleBuffered := True;
  PropPanel.DoubleBuffered := True;
  Self.ToggleChangeTag(True);
  Init;
end;

procedure TGreyDrawForm.UndoActionClick(Sender: TObject);
begin
  TGreyDrawFormat.LoadFromString(HistoryStepBack, True);
  AnchorsList.Clear;
end;

procedure TGreyDrawForm.ViewPortMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  BMouseDown := True;
  CurrentTool.MouseDown(X, Y, Shift);
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.ViewPortMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  CursorPos := Point(X, Y);
  CurrentTool.MouseMove(X, Y, Shift);
  if BMouseDown then
    Self.SetScrollRect;
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.ViewPortMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  BMouseDown := False;
  CurrentTool.MouseUp(X, Y, Shift);
  if CurrentTool.ClassParent <> TTool then
    HistoryPush(TGreyDrawFormat.SaveToString);
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.ViewPortMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if ssCtrl in Shift then
    if WheelDelta > 0 then
      Self.SPlusBtnClick(SPlusBtn)
    else
      Self.SMinusBtnClick(SMinusBtn)
  else if ssShift in Shift then
    with HScrollBar do
      SetParams(Position - WheelDelta, Min, Max)
  else
    with VScrollBar do
      SetParams(Position - WheelDelta, Min, Max);
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.ViewPortPaint(Sender: TObject);
var
  i: Integer;
begin
  FirstBuffer.Fill(clWhite);
  for i := 0 to High(FiguresList) do
    FiguresList[i].Draw(FirstBuffer);
  for i := 0 to High(FiguresList) do
    if FiguresList[i].Hovered or FiguresList[i].Selected then
      FiguresList[i].DrawSelection(FirstBuffer);
  for i := AnchorsList.Count - 1 downto 0 do
    (AnchorsList.Items[i] as TVertexAnchor).Draw(FirstBuffer);
  with SelectionRect do
  begin
    FirstBuffer.PenStyle := psDash;
    FirstBuffer.RectangleAntialias(Left, Top, Right, Bottom, SelectedColor, 1);
  end;
  FirstBuffer.Draw(ViewPort.Canvas, 0, 0, True);
end;

procedure TGreyDrawForm.ViewPortResize(Sender: TObject);
begin
  VScrollBar.PageSize := ViewPort.Height;
  HScrollBar.PageSize := ViewPort.Width;
  Self.SetScrollRect;
  ViewPort.Invalidate;
end;

procedure TGreyDrawForm.CreateToolButtons;
var
  i: Integer;
  Button: TToolButton;
begin
  for i := 0 to High(FigureToolsList) do
  begin
    Button := TToolButton.Create(ToolsPanel);
    with Button do
    begin
      Parent := ToolsPanel;
      Height := 30;
      Width := 30;
      Left := 15;
      Top := i * Height + (i + 1) * Left;
      Name := FigureToolsList[i].ClassName();
      Glyph := LoadImage(FigureToolsList[i].Image);
      Hint := FigureToolsList[i].Hint;
      Tool := FigureToolsList[i];
      ShowHint := True;
      OnClick := @ToolButtonClick;
      DoubleBuffered := True;
    end;
  end;
end;

procedure TGreyDrawForm.SetScrollRect;
var
  R: TRectF;
begin
  R := ScrollRect(RectF(0, 0, ViewPort.Width, ViewPort.Height));
  with HScrollBar do
  begin
    Min := trunc(R.Left);
    Max := ceil(R.Right);
    Enabled := abs(Max - Min) > ViewPort.Width;
  end;
  with VScrollBar do
  begin
    Min := trunc(R.Top);
    Max := ceil(R.Bottom);
    Enabled := abs(Max - Min) > ViewPort.Height;
  end;
end;

procedure TGreyDrawForm.SetScale(AScale: float);
begin
  if AScale > MaxScale then
    AScale := MaxScale;
  if AScale < MinScale then
    AScale := MinScale;
  Scaling := AScale;
  SNormalBtn.Caption := Format('%3.1f%%', [AScale * 100]);
end;

procedure TGreyDrawForm.SetExportFormats;
var
  i: Integer;
begin
  for i := 0 to High(ExporterList) do
    ExportDalog.Filter := Concat(ExportDalog.Filter, ExporterList[i].FormatString, '|');
  ExportDalog.Filter := Copy(ExportDalog.Filter, 0, Length(ExportDalog.Filter) - 1);
end;

procedure TGreyDrawForm.SetSaveFormats;
var
  i: Integer;
begin
  for i := 0 to High(FormatList) do
    FODialog.Filter := Concat(FODialog.Filter, FormatList[i].FormatString, '|');
  FODialog.Filter := Copy(FODialog.Filter, 0, Length(FODialog.Filter) - 1);
  FSDialog.Filter := FODialog.Filter;
end;

function TGreyDrawForm.SaveAction: Integer;
begin
  if FileExists(FileName) then
  begin
      if FormatList[FormatIndex].TestSaveFile(FileName) then
      begin
        FormatList[FormatIndex].SaveToFile(FileName);
        Self.ToggleChangeTag(False);
        exit(1);
      end;
  end;
  if FSDialog.Execute then
  begin
    if FileExists(FSDialog.FileName) then
      if MessageDlg('Вы хотите перезаписать файл?', mtWarning, mbYesNo, 0) <>
        mrYes then
        exit(0);
    FileName := FSDialog.FileName;
    FormatIndex := FSDialog.FilterIndex - 1;
    if FormatList[FormatIndex].TestSaveFile(FileName) then
      FormatList[FormatIndex].SaveToFile(FileName);
  end;
  Self.ToggleChangeTag(False);
  Result := 1;
end;

function TGreyDrawForm.CanBeClosed: Boolean;
var
  s: String;
begin
  Result := False;
  if HasUnsavedChanges then
    case MessageDlg('Сохранить изменения?',
        Concat('Сохранить изменения в "', FileName, '" перед закрытием?'),
        mtWarning, mbYesNoCancel, 0, mbCancel)
      of
      mrYes: if SaveAction = 1 then
          Result := True;
      mrNo: Result := True;
    end
  else
    Result := True;
end;

procedure TGreyDrawForm.ToggleChangeTag(AChanged: Boolean);
begin
  if AChanged then
  begin
    Self.Caption := Concat(ChangesTag, ' ', FileName, ' - GreyDraw');
    HasUnsavedChanges := True;
  end
  else
  begin
    Self.Caption := Concat(FileName, ' - GreyDraw');
    HasUnsavedChanges := False;
  end;
end;

procedure TGreyDrawForm.ExportItemClick(Sender: TObject);
var
  i: Integer;
begin
  if ExportDalog.Execute then
  begin
    if FileExists(ExportDalog.FileName) then
      if MessageDlg('Вы хотите перезаписать файл?', mtWarning, mbYesNo, 0) <> mrYes then
        exit;
    for i := 0 to High(ExporterList) do
      if ExporterList[i].TestFile(ExportDalog.FileName) then
      begin
        ExporterList[i].ExportData(ExportDalog.FileName);
        Break;
      end;
  end;
end;

procedure TGreyDrawForm.MenuItem3Click(Sender: TObject);
var
  F: TFigure;
  A: TVertexAnchor;
  Sel: Boolean = True;
  i: Integer;
begin
  for F in FiguresList do
    if not F.Selected then
    begin
      Sel := False;
      Break;
    end;
  AnchorsList.Clear;
  if not Sel then
  begin
    for F in FiguresList do
    begin
      F.Selected := True;
      for i := 0 to F.PointsCount do
      begin
        A := AnchorsList.Add as TVertexAnchor;
        A.SetPoint(F.GetPointAddr(i));
        A.Selected := True;
      end;
    end;
  end
  else
    for F in FiguresList do
      F.Selected := False;
end;

initialization

end.
