unit uImgSlide;

interface

{$DEFINE XPress7}

uses
  Windows, Messages, SysUtils, Classes, Graphics, ComCtrls, Controls, Forms,
  Dialogs, Buttons, ExtCtrls, Menus, AxCtrls, OleCtrls, DbOleCtl, Math, UCSList,
  ImgeditLibCtl_TLB, ShareImgThumbnail, ShareMagnifier, ShareMag,//IMAGXPR6Lib_TLB;
  {$IFDEF XPress6}IMAGXPR6Lib_TLB{$Else}ImagXpr7_TLB{$ENDIF};


const
  Key_Enter = 13;
  Key_Escape = 27;
  Key_PageUp = 33;
  Key_PageDown = 34;
  Key_End = 35;
  Key_Home = 36;
  Key_Left = 37;
  Key_Up = 38;
  Key_Right = 39;
  Key_Down = 40;
  Key_Del =46;
  Key_F2 = 113;
  Key_ZoomIn = 187;
  Key_ZoomOut = 189;

type
  TLoadBuffer = class(TThread)
  private
    FPanelPreBuffer:TPanel;       //用于放置前一页buffer影像的panel
    FPanelNextBuffer:TPanel;      //用于放置后一页buffer影像的panel
    //FImgControl:TImgControl;
    PreBufferList:TList;
    NextBufferList:TList;

    Con:TWinControl;

    FCurPage:integer;
  public
    Constructor Create(CreateSuspended: Boolean;ACon:TWinControl;APreBufferpanel,ANextBufferPanel:TPanel;APreList,ANextList:TList);overload;
    Destructor Destroy;override;
    procedure Execute;override;
//    procedure CreateImgControl(AImgControl:TImgControl);
    procedure LoadBuffer;
  end;



type

  TViewImgListEvent = procedure (Sender : TObject; ThumbIndex,ThumbCount,ImgIndex:Integer) of Object;
  TImageChangeEvent = procedure (Sender : TObject;PreSelectThumbnail : TShareImgThumbnail) of Object;
  TImageSelected    = procedure (Sender : TObject;MouseDown:Boolean) of Object;
  TOpenImageErrorEvent = procedure (Sender : TObject;ErrorMsg : string) of Object;

  TShareIMGSlide = class(TScrollBox)
  private
    { Private declarations }
    FShowPart:Boolean;
    FPartLeft:Integer;
    FPartTop:Integer;
    FPartWidth:Integer;
    FPartHeight:Integer;
    FSbxPart:TScrollBox;
    FPanelPart:TPanel;
    FPartAlign:TAlign;
    FPartList:TList;
    FPartParent:TWinControl;
    FPartThumbnailMargin:Integer;
    FPartLabelVisible:Boolean;

    FImgControl : TImgControl;    //显示控件，现提供imgedit和imagxpress
    FUseBuffer : Boolean;         //显示时是否使用buffer，使用的话，每显示一页，则读取前一页和后一页影像在后台打开
    FPanelPreBuffer:TPanel;       //用于放置前一页buffer影像的panel
    FPanelNextBuffer:TPanel;      //用于放置后一页buffer影像的panel
    FLoadBuffer:TLoadBuffer;

    FPreBufferList:TList;
    FNextBufferList:TList;

    FKeyProcessing:Boolean;       //保证在翻页操作或其他影像操作的时候不能继续keydown
    FThumbCreating:Boolean;       //保证在创建缩略图的时候不做ScrollBoxResize操作
    FlvKey:TListView;             //用于执行键盘操作

    FRow:Integer;                 //当前的缩略图的行数
    FCol:Integer;                 //当前的缩略图的列数
    FThumbMargin:Integer;         //缩略图之间的间隔
    FThumbSelected:TShareImgThumbnail;  //当前选中的缩略图

    FThumbColor:TColor;                 //当前选中的缩略图的颜色
    FThumbList:TList;                   //当前的所有的缩略图列表

    FImgList:TStringList;          //所有的影像文件名的列表
    FPages:Integer;                //根据影像数和每页显示的缩略图数得出的总页数
    FCurrentPage:Integer;          //当前是第几页

    FPopupMenu:TPopupMenu;         //缩略图的右键菜单
    FViewMode:integer;             //显示模式 设为1时，显示1X1，而且图像为适应宽度，按上下方向进行影像的上翻下翻，左右键翻页

    FTimer:TTimer;
    FTimeInterval:Integer;         //自动浏览的时间间隔
    FStopped:Boolean;              //自动浏览是否停止
    FReverseSlide:Boolean;         //浏览的方向，是否反向浏览

    FUseMagnifier:Boolean;         //是否使用放大镜
    FUseXPressToolSetMagnifier:Boolean;
    FMagnifier:TShareMagnifier;    //放大镜
    FXPressMagnifier:TShareMag;
    FMagnifierParent:TWinControl;
    FLabelAlign : TLabelAlign;

    FSynColor:Boolean;
    FSynLabelColor:Boolean;
    FLockWindow:Boolean;

    FDbClickViewOneImg:Boolean;        //双击单张图是否调用放大界面,调用的话,本控件的双击事件不可用
    FRefreshEndViewOneImg:Boolean;     //显示单张界面关闭后回到主界面是否更新到单张看的那张影像

    FOnImgChange : TImageChangeEvent;
    FOnPageChange : TNotifyEvent;
    FOnPageView : TViewImgListEvent;
    FOnImgViewed : TNotifyEvent;
    FOnKeyDown : TKeyEvent;
    FOnOpenImageError : TOpenImageErrorEvent;  //碰到影像损坏或者OIEng400.dll出错误时，开放出的事件，供应用程序作相应处理

    FOnImgSelect : TImageSelected;//TNotifyEvent;
    FSelectByMouse:Boolean; //是通过键盘选择影像还是鼠标
    FPageChanged:Boolean;  //是否换页了
    FVALLImage:Boolean;   //翻页的时候是否等显示完所有影像才可以翻
    FEnterKeySMDBClick:Boolean;//回车键与双击事件相同

    FViewMiddleLine:Boolean;  //是否显示中线
    FMiddleLineType:integer;  //中线的类型 ，0为纵向，1为横向
    procedure OnlvKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CreateThumbnail(AParent:TWinControl);     //创建缩略图，并设置缩略图列表
    procedure SetImgList(AImgList: TStringList);
    procedure OnImgSelected(Sender: TObject);
    procedure OnImgViewed(Sender: TObject);
    procedure OnPartImgSelected(Sender: TObject);
    procedure ScrollBoxResize(Sender: TObject);
    procedure OnlvKeyResize(Sender: TObject);
    procedure OnPartResize(Sender: TObject);
    function GetThumbIndex:integer;
    function GetImageIndex:integer;
    function GetThumbByIndex(AIndex: Integer):TShareImgThumbnail;
    function GetThumbnailCount:integer;
    procedure TimerEvent(Sender: TObject);
    procedure SetPartLabelName(Sender: TObject);
    procedure SetPartLabelColor(Sender: TObject);
    procedure SetPartForeColor(Sender: TObject);
    procedure SelectThumbnail(Sender: TObject);
  protected
    { Protected declarations }
    function  FindLeftThumbnail(curThumbnail:TShareImgThumbnail):TShareImgThumbnail;
    function  FindRightThumbnail(curThumbnail:TShareImgThumbnail):TShareImgThumbnail;
    function  FindUpThumbnail(curThumbnail:TShareImgThumbnail):TShareImgThumbnail;
    function  FindDownThumbnail(curThumbnail:TShareImgThumbnail):TShareImgThumbnail;
    function  FindPageUpThumbnail(curThumbnail:TShareImgThumbnail):TShareImgThumbnail;
    function  FindPageDownThumbnail(curThumbnail:TShareImgThumbnail):TShareImgThumbnail;
    function  FindHomeThumbnail(curThumbnail:TShareImgThumbnail):TShareImgThumbnail;
    function  FindEndThumbnail(curThumbnail:TShareImgThumbnail):TShareImgThumbnail;

    procedure CreateBufferImgControl;

    procedure SetRows(AValue:Integer);
    procedure SetCols(AValue:Integer);
    procedure SetThumbMargin(AValue:Integer);
    procedure SetTimeInterval(AValue:Integer);
    procedure SetShowPart(AValue:Boolean);
    procedure SetPartLabelVisible(AValue:Boolean);
    procedure SetPartAlign(AValue:TAlign);
    procedure SetMagParent(AValue:TWinControl);
    procedure SetPartParent(AValue:TWinControl);
    procedure SetPartLeft(AValue:Integer);
    procedure SetPartTop(AValue:Integer);
    procedure SetPartWidth(AValue:Integer);
    procedure SetPartHeight(AValue:Integer);
    procedure SetPartThumbnailMargin(AValue:Integer);
    procedure SetMagnifier(AValue:Boolean);
    procedure SetMagnifierImgEdit(Sender : TObject);
    procedure SetSynLabelColor(Value: Boolean);
    procedure SetSynColor(Value: Boolean);
    procedure SetXPressOwnMagnifier(Value:Boolean);
    procedure SetMiddleLine(Value:Boolean);
    procedure SetMiddleLineType(Value:integer);
    procedure SetLabelAlign(Value : TLabelAlign);
    procedure SetViewMode(AViewMode:integer);
  public
    { Public declarations }
    AlwaysFocus:Boolean;
    nThreads:integer;
    BufferCSList:TCSList;
    procedure SetImgControl(AValue:TImgControl);
    procedure SetUseBuffer(Value: Boolean);
    //属性
    property Selected : TShareImgThumbnail read FThumbSelected write FThumbSelected;
    property SelThumbnailIndex : Integer read GetThumbIndex;
    property SelImageIndex : Integer read GetImageIndex;
    property ImageList : TStringList read FImgList write SetImgList;
    property nThumbnails : Integer read GetThumbnailCount;
    property nPages : Integer read FPages;
    property CurPage : Integer read FCurrentPage;

    property ThumbnailList[Index:integer] : TShareImgThumbnail read GetThumbByIndex;
    //property ImgControl:TImgControl read FImgControl;

    //方法
    constructor Create(AOwner : TComponent);override;
    destructor Destroy;override;
    procedure SetFocus;override;
    procedure NextPage;
    procedure PriorPage;
    procedure FirstPage;
    procedure LastPage;
    procedure ViewPage(APageIndex:integer=1);
    procedure ViewImage(AImageName:string);overload;
    procedure ViewImage(AImageIndex: integer;RefreshPage:Boolean=False);overload;
    procedure ResetSlideForm(ARow:integer=2;ACol:integer=3);   //重新设置行列
    procedure ResizeAll;
    procedure SetPopupMenu(pop : TPopupMenu);
    procedure StartSlide(AFromFirstPage:Boolean=False);  //开始自动浏览 可设置是从当前页继续浏览还是从第一页开始
    procedure StopSlide;
    procedure SetThumbnailColor(AThumbIndex:Integer;AColor:TColor);
    procedure SetThumbnailPalette(AThumbIndex:integer;APalette:integer);
    procedure Refresh;overload;
    procedure SetPartRect(ALeft,ATop,AWidth,AHeight:Integer);overload;
    procedure SetPartRect(AthumbIndex,ALeft,ATop,AWidth,AHeight:Integer);overload;
    procedure Clear;
    procedure AddImage(AFileName:string;AHandle:THandle=0;ViewCurImg:Boolean=True);
    procedure InsertImage(AImageIndex:Integer;AFileName:string;ViewCurImg:Boolean=True);
    procedure ReplaceImage(AImageIndex:Integer;AFileName:string;ViewCurImg:Boolean=True);
    procedure DeleteImage(AImageIndex: Integer;ARefresh:Boolean=True);
    procedure DeleteSelectImage;

    procedure OnLoadBufferThreadTerminate(Sender: TObject);
    procedure CreateImagebuffer;
  published
    { Published declarations }
    property ImgControl:TImgControl read FImgControl write SetImgControl;
    property ViewMode:integer read FViewMode Write SetViewMode;
    //property UseBuffer:Boolean read FUseBuffer write SetUseBuffer;
    property PartSbx:TScrollBox read FSbxPart;
    property ShowPart:Boolean Read FShowPart Write SetShowPart;
    property PartLabelVisible:Boolean Read FPartLabelVisible Write SetPartLabelVisible;
    property PartAlign:TAlign read FPartAlign write SetPartAlign;
    property MagnifierParent:TWinControl read FMagnifierParent write SetMagParent;
    property PartParent:TWinControl read FPartParent write SetPartParent;
    property PartLeft:Integer read FPartLeft write SetPartLeft;
    property PartTop:Integer read FPartTop write SetPartTop;
    property PartWidth:Integer read FPartWidth write SetPartWidth;
    property PartHeight:Integer read FPartHeight write SetPartHeight;
    property PartThumbnailMargin:Integer read FPartThumbnailMargin write SetPartThumbnailMargin default 2;
    property Rows : Integer read FRow write SetRows;
    property Cols : Integer read FCol write SetCols;
    property Interval : Integer read FTimeInterval write SetTimeInterval default 3;
    property ReverseSlide:Boolean Read FReverseSlide Write FReverseSlide;
    property ThumbnailMargin : Integer read FThumbMargin write SetThumbMargin;
    property UseMagnifier : Boolean read FUseMagnifier write SetMagnifier;
    property DbClickViewOneImg : Boolean read FDbClickViewOneImg write FDbClickViewOneImg;
    property RefreshEndViewOneImg : Boolean read FRefreshEndViewOneImg write FRefreshEndViewOneImg;
    property OnImageChange : TImageChangeEvent read FOnImgChange write FOnImgChange;
    property OnImgSelect : TImageSelected read FOnImgSelect write FOnImgSelect;
    property OnImageViewed : TNotifyEvent read FOnImgViewed write FOnImgViewed;
    property OnPageChange : TNotifyEvent read FOnPageChange write FOnPageChange;
    property OnPageView : TViewImgListEvent read FOnPageView write FOnPageView;
    property OnKeyDown : TKeyEvent read FOnKeyDown write FOnKeyDown;
    property OnOpenImageError : TOpenImageErrorEvent read FOnOpenImageError write FOnOpenImageError;
    property SynColor : Boolean read FSynColor Write SetSynColor;
    property SynLabelColor : Boolean read FSynLabelColor Write SetSynLabelColor;
    property PopupMenu : TPopupMenu read FPopupMenu write SetPopupMenu;
    property LockWindow : Boolean read FLockWindow write FLockWindow;
    property UseXPressToolSetMagnifier : Boolean read FUseXPressToolSetMagnifier write SetXPressOwnMagnifier;
    property ViewMiddleLine: Boolean read FViewMiddleLine Write SetMiddleLine;
    property MiddleLineType: integer read FMiddleLineType Write SetMiddleLineType;
    property VALLImage: Boolean read FVALLImage Write FVALLImage;
    property LabelAlign : TLabelAlign read FLabelAlign write SetLabelAlign;
    property EnterKeySMDBClick : Boolean read FEnterKeySMDBClick write FEnterKeySMDBClick; 
  end;

procedure Register;

implementation

uses fmViewOneImage, uImageBuffer;

var
  bLoadingBuffer:Boolean;


procedure Register;
begin
  RegisterComponents('ShareVCL', [TShareIMGSlide]);
end;

{ TShareImgThumbnail }

constructor TShareIMGSlide.Create(AOwner: TComponent);
begin
  inherited;
  nThreads:=0;
  AlwaysFocus:=True;
  BufferCSList:=TCSList.Create;
  FSelectByMouse:=True;
  
  FPartParent:=self.Parent;
  FShowPart:=False;
  FKeyProcessing:=False;
  FThumbCreating:=False;
  FLabelAlign:=alBottom;
  FEnterKeySMDBClick:=True;
  //自己的属性设置
  //外面如果有onResize事件会冲掉，而且默认2*3，如果 Object Inspector里不是，
  //那么，align=client,form一开就最大化，此时self的高和宽还是界面上那么大，不刷新，
  //因此resize移到lvKey的resize中去
  //self.OnResize:=ScrollBoxResize;
  //创建listview用于键盘操作
  FlvKey:=TListView.Create(self);
  FlvKey.Parent:=self;
  FlvKey.Color:=clBtnFace;
  FlvKey.Align:=alClient;
  FlvKey.OnKeyDown:=OnlvKeyDown;
  FlvKey.OnResize:=OnlvKeyResize;

  FSbxPart:=TScrollBox.Create(self);
  FSbxPart.Parent:=FPartParent;
  FSbxPart.Visible:=ShowPart;
  FPanelPart:=TPanel.Create(self);
  FPanelPart.Parent:=FSbxPart;
  FPanelPart.OnResize:=self.OnPartResize;
  FPanelPart.Align:=alClient;
  FPanelPart.ParentColor:=True;
  FPanelPart.BorderStyle:=bsNone;
  FPanelPart.BevelOuter:=bvNone;
  FPanelPart.BevelInner:=bvNone;

  FMagnifier:=TShareMagnifier.Create(self);
  FUseMagnifier:=False;
  FXPressMagnifier:=TShareMag.Create(self);
  FMagnifierParent:=self;
  FXPressMagnifier.Parent:=FMagnifierParent;
  FUseXPressToolSetMagnifier:=False;
  FDbClickViewOneImg:=False;
  FRefreshEndViewOneImg:=True;

  FPartAlign:=alClient;
  //buffer
  FUseBuffer:=False;
  FPanelPreBuffer:=TPanel.Create(self);
  FPanelPreBuffer.Parent:=self;
  FPanelPreBuffer.Width:=0;
  FPanelPreBuffer.Height:=0;
  FPanelPreBuffer.Tag:=-1;

  FVALLImage:=true;


  FPanelNextBuffer:=TPanel.Create(self);
  FPanelNextBuffer.Parent:=self;
  FPanelNextBuffer.Width:=0;
  FPanelNextBuffer.Height:=0;
  FPanelNextBuffer.Tag:=-1;

  FPreBufferList:=TList.Create;
  FNextBufferList:=TList.Create;

  FLoadBuffer:=nil;//TLoadBuffer.Create(False,self,FPanelPreBuffer,FpanelNextBuffer);

  //默认缩略图为6个，两行三列
  FRow:=2;
  FCol:=3;
  FThumbMargin:=3;
  FPartThumbnailMargin:=2;
  FThumbColor:=clBtnFace;

  FPopupMenu:=nil;
  FTimer:=TTimer.Create(self);
  FTimer.Enabled:=False;
  FTimer.OnTimer:=TimerEvent;
  if FTimeInterval>0 then
    FTimer.Interval:=FTimeInterval;
  FStopped:=True;

  FCurrentPage:=1;
  FPages:=1;

  FImgList:=TStringList.Create;
  FThumbList:=TList.Create;
  CreateThumbnail(self);
//  Initialize;
  FImgControl:=icImgEdit;
  self.SetImgControl(FImgControl);
end;

destructor TShareIMGSlide.Destroy;
begin
//  self.SetMagnifier(False);
  BufferCSList.Free;
  FThumbList.Free;
  FImgList.Free;
  try
    FPreBufferList.Free;;
    FNextBufferList.Free;
    if FPartList<>nil then
      FPartList.Free;
    if FLoadBuffer<>nil then
      FLoadBuffer.Terminate;
  except
  end;
  FPartList:=nil;
  while nThreads>0 do
  begin
    //showmessage('can''t close');
  end;
  inherited;
end;

procedure TShareIMGSlide.OnlvKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  thumbnailToSelect : TShareImgThumbnail;
begin
  if (FKeyProcessing) then
  begin
    Exit;
  end;
  FKeyProcessing := TRUE;
  thumbnailToSelect := nil;
  if shift=[] then
  begin
    case Key of
      Key_Left:
      begin
        thumbnailToSelect := FindLeftThumbnail(FThumbSelected);
      end;
      Key_Right:
      begin
        thumbnailToSelect := FindRightThumbnail(FThumbSelected);
      end;
      Key_Up:
      begin
        if self.FViewMode=1 then
          self.ThumbnailList[0].ImgXPressCtrl.ScrollY:=self.ThumbnailList[0].ImgXPressCtrl.ScrollY-self.ThumbnailList[0].ImgXPressCtrl.Height
        else
          thumbnailToSelect := FindUpThumbnail(FThumbSelected);
      end;
      Key_Down:
      begin
        if self.FViewMode=1 then
          self.ThumbnailList[0].ImgXPressCtrl.ScrollY:=self.ThumbnailList[0].ImgXPressCtrl.ScrollY+self.ThumbnailList[0].ImgXPressCtrl.Height
        else
          thumbnailToSelect := FindDownThumbnail(FThumbSelected);
      end;
      Key_Home:
      begin
        thumbnailToSelect := FindHomeThumbnail(FThumbSelected);
      end;
      Key_End:
      begin
        thumbnailToSelect := FindEndThumbnail(FThumbSelected);
      end;
      Key_PageUp:
      begin
        thumbnailToSelect := FindPageUpThumbnail(FThumbSelected);
      end;
      Key_PageDown:
      begin
        thumbnailToSelect := FindPageDownThumbnail(FThumbSelected);
      end;
      Key_Enter:
      begin
        if self.FEnterKeySMDBClick then
          OnImgViewed(FThumbSelected);
      end;
    end;
//    else
  end;
    begin
      if Assigned(FOnKeyDown) then
        FOnKeyDown(self,Key,Shift);
    end;
  if (thumbnailToSelect <> nil) then// and (thumbnailToSelect <> FThumbSelected) then
  begin
    //OnImgSelected(thumbnailToSelect);
    FSelectByMouse:=False;
    SelectThumbnail(thumbnailToSelect);
  end;
  if FVALLImage then
    Application.ProcessMessages;//此行可以保证xpress的时候刷新完界面后才执行后面的代码
  FKeyProcessing := FALSE;
end;

procedure TShareIMGSlide.CreateThumbnail(AParent:TWinControl);
var
  i,j:integer;
  tmpThumb:TShareImgThumbnail;
begin
  try
    FThumbCreating:=True;
    for i:=0 to FRow-1 do
      for j:=0 to FCol-1 do
      begin
        tmpThumb:=TShareImgThumbnail.Create(AParent);
        tmpThumb.OnMouseDown:=self.OnMouseDown;
        tmpThumb.Parent:=AParent;
        tmpThumb.SetImgControl(FImgControl);
        if AParent=FSbxPart then
        begin
          tmpThumb.ShowPart:=FShowPart;
          tmpThumb.LabelVisible:=FPartLabelVisible;
          tmpThumb.ThumbnailMargin:=FPartThumbnailMargin;
          //self.FPartThumbnailMargin:=2;
          //add 2004/3/3  可以选中小图
          tmpThumb.OnThumbnailSelected:=OnPartImgSelected;
          tmpThumb.OnImgViewed:=OnImgViewed;

          if FUseMagnifier then
            if FImgControl=icImgEdit then
            begin
              tmpThumb.ImgEditCtrl.OnEnter:=SetMagnifierImgEdit;
              tmpThumb.ImgEditCtrl.Enabled:=True;
            end
            else if FImgControl=icImagXPress then
            begin
              tmpThumb.ImgXPressCtrl.Enabled:=True;
              if FUseXPressToolSetMagnifier then
              begin
                {$IFNDEF XPress6}
                tmpThumb.ImgXPressCtrl.ToolSet(Tool_Mag,IXMOUSEBUTTON_Left,IXKEY_None);
                tmpThumb.ImgXPressCtrl.ToolSetAttribute(Tool_Mag,TOOLATTR_MagWidth,200);
                tmpThumb.ImgXPressCtrl.ToolSetAttribute(Tool_Mag,TOOLATTR_MagHeight,200);
                //放大镜中显示100%原始大小
                tmpThumb.ImgXPressCtrl.ToolSetAttribute(Tool_Mag,TOOLATTR_MagFactor,Min(Trunc(100/tmpThumb.ImgXPressCtrl.IPZoomF),1000));
                {$ENDIF}
              end
              else
                tmpThumb.ImgXPressCtrl.OnEnter:=SetMagnifierImgEdit;
            end
            else if FImgControl=icImgShare then
            begin
              //to be add
              tmpThumb.ImgShare.Enabled:=True;
            end;
          if FPopupMenu<>nil then
            tmpThumb.SetPopupMenu(FPopupMenu);
          tmpThumb.SetPartRect(FPartLeft,FPartTop,FPartWidth,FPartHeight);
          FPartList.Add(tmpThumb);
        end
        else
        begin
          tmpThumb.ShowPart:=False;
          tmpThumb.OnThumbnailSelected:=SelectThumbnail; //OnImgSelected;
          tmpThumb.OnImgViewed:=OnImgViewed;
          tmpThumb.OnSetFileName:=SetPartLabelName;
          if FUseMagnifier then
            if FImgControl=icImgEdit then
            begin
              tmpThumb.ImgEditCtrl.OnEnter:=SetMagnifierImgEdit;
              tmpThumb.ImgEditCtrl.Enabled:=True;
            end
            else if FImgControl=icImagXPress then
            begin
              tmpThumb.ImgXPressCtrl.Enabled:=True;
              if FUseXPressToolSetMagnifier then
              begin
                {$IFNDEF XPress6}
                tmpThumb.ImgXPressCtrl.ToolSet(Tool_Mag,IXMOUSEBUTTON_Left,IXKEY_None);
                tmpThumb.ImgXPressCtrl.ToolSetAttribute(Tool_Mag,TOOLATTR_MagWidth,200);
                tmpThumb.ImgXPressCtrl.ToolSetAttribute(Tool_Mag,TOOLATTR_MagHeight,200);
                //放大镜中显示100%原始大小
                tmpThumb.ImgXPressCtrl.ToolSetAttribute(Tool_Mag,TOOLATTR_MagFactor,Min(Trunc(100/tmpThumb.ImgXPressCtrl.IPZoomF),1000));
                {$ENDIF}
              end
              else
                tmpThumb.ImgXPressCtrl.OnEnter:=SetMagnifierImgEdit;
            end
            else if FImgControl=icImgShare then
            begin
              //to be add
              tmpThumb.ImgShare.Enabled:=True;
            end;
          if FPopupMenu<>nil then
            tmpThumb.SetPopupMenu(FPopupMenu);
          FThumbList.Add(tmpThumb);
        end;
        tmpThumb.LabelAlign:=self.FLabelAlign;
      end;
    FThumbCreating:=False;
    ScrollBoxResize(AParent);
  except
  end;
end;

procedure TShareIMGSlide.OnImgSelected(Sender: TObject);
var
  bChange:Boolean;
  preSelected:TShareImgThumbnail;
begin
  try
    try
      preSelected:=nil;
    {    if FUseMagnifier then
        begin
          if FThumbSelected.ImgFileName<>'' then
          begin
            FThumbSelected.ImgEditCtrl.Enabled:=True;
            FMagnifier.ImgEdit:=FThumbSelected.ImgEditCtrl;
          end;
        end
        else}
        begin

              if (self.AlwaysFocus) or (self.FSelectByMouse) then
                FlvKey.SetFocus;

          bChange:=True;
          if FThumbSelected <> nil then
            if FThumbSelected<>TShareImgThumbnail(Sender) then  //如果选择的影像与原来的选中影像不同则对thumbnailselected重新赋值
            begin
              FThumbSelected.Selected := FALSE;
              preSelected:=FThumbSelected;
            end
            else
              bChange:=False;

          FThumbSelected := TShareImgThumbnail(Sender);
          if not FThumbSelected.Selected then
          begin
            FThumbSelected.OnThumbnailSelected:=nil;
            FThumbSelected.Selected:=True;
            FThumbSelected.OnThumbnailSelected:=SelectThumbnail;
          end;
          if FShowPart then
          begin
            if not TShareImgThumbnail(FPartList[FThumbList.IndexOf(TShareImgThumbnail(FThumbSelected))]).Selected then
            begin
              TShareImgThumbnail(FPartList[FThumbList.IndexOf(TShareImgThumbnail(FThumbSelected))]).OnThumbnailSelected:=nil;
              TShareImgThumbnail(FPartList[FThumbList.IndexOf(TShareImgThumbnail(FThumbSelected))]).Selected:=True;
              TShareImgThumbnail(FPartList[FThumbList.IndexOf(TShareImgThumbnail(FThumbSelected))]).OnThumbnailSelected:=OnPartImgSelected;
            end;
            if preSelected<>nil then
              TShareImgThumbnail(FPartList[FThumbList.IndexOf(TShareImgThumbnail(preSelected))]).Selected:=False;
          end;

          //选中的图变了，或者选中图没变，但是不是同一页了，那么
          //if preselected<>nil then
          //  showmessage(PreSelected.ImgFileName+'   '+self.FThumbSelected.ImgFileName);
          if (bChange) or ((not bChange) and FPageChanged) then
          begin
            FPageChanged:=False;
            if Assigned(FOnImgChange) then
              FOnImgChange(self,PreSelected);
          end;
        end;
    except
    end;
  finally
    FPageChanged:=False;
  end;
end;

procedure TShareIMGSlide.OnImgViewed(Sender: TObject);
var
  nImgIndex:integer;
begin
  if FDbClickViewOneImg then
  begin
    if (FThumbSelected<>nil) and (FThumbSelected.ImgFileName<>'') then
    begin
      nImgIndex:=self.GetImageIndex;
      frmViewOneImage:=nil;
      frmViewOneImage:=TfrmViewOneImage.create(self);
      frmViewOneImage.Execute(FImgList,nImgIndex);
      frmViewOneImage.Free;
      if FRefreshEndViewOneImg then
        self.ViewImage(nImgIndex);
    end;
  end
  else
    if Assigned(FOnImgViewed) then
      FOnImgViewed(Sender);
end;

procedure TShareIMGSlide.OnPartResize(Sender: TObject);
begin
  self.ScrollBoxResize(self.FSbxPart);
end;

procedure TShareIMGSlide.OnlvKeyResize(Sender: TObject);
begin
  self.ScrollBoxResize(self);
end;

procedure TShareIMGSlide.ScrollBoxResize(Sender: TObject);
var
  i,nTemp:integer;
  tHeight,tWidth:integer;

begin
//  showmessage('aa');
  if FThumbCreating then
    Exit;
  inherited;
  try
    //调节所略图大小
    try
      if self.FLockWindow then
        LockWindowUpdate(TWinControl(Sender).Handle);
      nTemp:=3;
      if self.nThumbnails=1 then nTemp:=4;
      tHeight:=(TWinControl(Sender).Height-(FRow-1)*FThumbMargin-nTemp-(1 div FRow)) div FRow;
      tWidth:=(TWinControl(Sender).Width-(FCol-1)*FThumbMargin-nTemp-(1 div FCol)) div FCol;
      for i:=0 to nThumbnails-1 do
      begin
        if Sender=self then
        begin
          TShareImgThumbnail(FThumbList[i]).Height:=tHeight;
          TShareImgThumbnail(FThumbList[i]).Width:=tWidth;
          TShareImgThumbnail(FThumbList[i]).Left:=(i mod FCol)*(tWidth+FThumbMargin-1);
          TShareImgThumbnail(FThumbList[i]).Top:=(i div FCol)*(tHeight+FThumbMargin-1);
        end
        else if Sender=FSbxPart then
        begin
          TShareImgThumbnail(FPartList[i]).Height:=tHeight;
          TShareImgThumbnail(FPartList[i]).Width:=tWidth;
          TShareImgThumbnail(FPartList[i]).Left:=(i mod FCol)*(tWidth+FThumbMargin-1);
          TShareImgThumbnail(FPartList[i]).Top:=(i div FCol)*(tHeight+FThumbMargin-1);
        end;
      end;
    except
    end;
  finally
    if self.LockWindow then
      LockWindowUpdate(0);
  end;
end;

function TShareIMGSlide.FindPageUpThumbnail(
  curThumbnail: TShareImgThumbnail): TShareImgThumbnail;
begin
  //PriorPage;
  //result:=TShareImgThumbnail(FThumbList[0]);
  if FCurrentPage>1 then
  begin
    ViewPage(FCurrentPage-1);
    result:=TShareImgThumbnail(FThumbList[0]);//FThumbSelected;
  end;
end;

function TShareIMGSlide.FindPageDownThumbnail(
  curThumbnail: TShareImgThumbnail): TShareImgThumbnail;
begin
  result:=curThumbnail;
  if FCurrentPage>=FPages then
    Exit;
  //NextPage;
  //nIndex:=0;

  //result:=TShareImgThumbnail(FThumbList[nIndex]);
  ViewPage(FCurrentPage+1);
  Result:=TShareImgThumbnail(FThumbList[0]);//FThumbSelected;
end;

function TShareIMGSlide.FindHomeThumbnail(
  curThumbnail: TShareImgThumbnail): TShareImgThumbnail;
begin
  //FirstPage;
  //result := FThumbList[0];
  if FCurrentPage>1 then
    ViewPage(1);
  result:=FThumbList[0];
end;

function TShareIMGSlide.FindEndThumbnail(
  curThumbnail: TShareImgThumbnail): TShareImgThumbnail;
var
  i:integer;
  nIndex:integer;
begin
  {LastPage;
  nIndex:=0;
  for i:=nThumbnails-1 downto 0 do
    if TShareImgThumbnail(FThumbList[i]).Visible then
    begin
      nIndex:=i;
      break;
    end;
  result := FThumbList[nIndex];}

  if FCurrentPage<FPages then
    ViewPage(FPages);
  nIndex:=FImgList.Count mod (nThumbnails)-1;
  if nIndex<0 then nIndex:=nThumbnails-1;
  result:=FThumbList[nIndex];
end;

function TShareIMGSlide.FindUpThumbnail(
  curThumbnail: TShareImgThumbnail): TShareImgThumbnail;
var
  nIndex : Integer;
begin
  nIndex:=FThumbList.IndexOf(curThumbnail);
  if nIndex=0 then
  begin
    //PriorPage;
    //result:=FThumbList[nThumbnails-1];
    result:=FindLeftThumbnail(curThumbnail);
    Exit;
  end
  else
    if nIndex-FCol>=0 then
      nIndex:=nIndex-FCol;

  result:=FThumbList[nIndex];
end;

function TShareIMGSlide.FindDownThumbnail(
  curThumbnail: TShareImgThumbnail): TShareImgThumbnail;
var
  nIndex : Integer;
begin
  nIndex:=FThumbList.IndexOf(curThumbnail);
  if nIndex=self.nThumbnails-1 then
  begin
    result:=self.FindRightThumbnail(curThumbnail);
    Exit;
  end
  else
    if nIndex+FCol<nThumbnails then
      if TShareImgThumbnail(FThumbList[nIndex+FCol]).Visible then
        nIndex:=nIndex+FCol;

  result:=FThumbList[nIndex];
end;

function TShareIMGSlide.FindLeftThumbnail(
  curThumbnail: TShareImgThumbnail): TShareImgThumbnail;
var
  nIndex  : Integer;
begin
  nIndex:=FThumbList.IndexOf(curThumbnail);
  if nIndex=0 then
  begin
    result:=curThumbnail;
    if FCurrentPage=1 then
      Exit;
    //PriorPage;
    ViewPage(FCurrentPage-1);
    result:=FThumbList[nThumbnails-1];
    Exit;
  end
  else
    nIndex:=nIndex-1;

  result:=FThumbList[nIndex];
end;

function TShareIMGSlide.FindRightThumbnail(
  curThumbnail: TShareImgThumbnail): TShareImgThumbnail;
var
  nIndex  : Integer;
begin
  nIndex:=FThumbList.IndexOf(curThumbnail);
  if nIndex=nThumbnails-1 then
  begin
    //result:=self.FindPageDownThumbnail(curThumbnail);
    //Exit;
    if FCurrentPage<FPages then
    begin
      ViewPage(FCurrentPage+1);
      nIndex:=0;
    end;
  end
  else
    if nIndex<nThumbnails-1 then
      if TShareImgThumbnail(FThumbList[nIndex+1]).Visible then
        nIndex:=nIndex+1;

  result:=FThumbList[nIndex];
end;

procedure TShareIMGSlide.FirstPage;
begin
  if FCurrentPage<>1 then
  begin
    ViewPage(1);
    FSelectByMouse:=False;
    //SelectThumbnail(FThumbSelected);
    SelectThumbnail(FThumbList[0]);
  end;
end;

procedure TShareIMGSlide.LastPage;
begin
  if FCurrentPage<>FPages then
  begin
    ViewPage(FPages);
    FSelectByMouse:=False;
    //SelectThumbnail(FThumbSelected);
    SelectThumbnail(FThumbList[0]);
  end;
end;

procedure TShareIMGSlide.NextPage;
begin
  if FCurrentPage+1<=FPages then
  begin
    ViewPage(FCurrentPage+1);
    FSelectByMouse:=False;
    //SelectThumbnail(FThumbSelected);
    SelectThumbnail(FThumbList[0]);
  end;
end;

procedure TShareIMGSlide.PriorPage;
begin
  if FCurrentPage-1>=1 then
  begin
    ViewPage(FCurrentPage-1);
    FSelectByMouse:=False;
    //SelectThumbnail(FThumbSelected);
    SelectThumbnail(FThumbList[0]);
  end;
end;

function TShareIMGSlide.GetThumbIndex:integer;
begin
  result:=-1;
  if FThumbSelected<>nil then
    result:=FThumbList.IndexOf(FThumbSelected);
end;

function TShareIMGSlide.GetImageIndex: integer;
begin
  result:=-1;
  if FThumbSelected<>nil then
  begin
    result:=(nThumbnails)*(FCurrentPage-1)+GetThumbIndex;
    if result>FImgList.Count-1 then
      result:=-1;
  end;
end;

procedure TShareIMGSlide.ViewPage(APageIndex:integer=1);
var
  i:integer;
  bThreadRunning:Boolean;
  PreThumbSelected:TShareImgThumbnail;
begin
  if APageIndex>FPages then
    APageIndex:=FPages;
  if APageIndex<=0 then
    Exit;

  FPageChanged:=FCurrentPage<>APageIndex;

  PreThumbSelected:=self.FThumbSelected;
  if APageIndex<=FPages then
  begin
    try
      if self.LockWindow then
      begin
        LockWindowUpdate(self.Handle);
        if FShowPart then
          LockWindowUpdate(FPartParent.Handle);
      end;
      FCurrentPage:=APageIndex;

      bThreadRunning:=False;
      if (FUseBuffer) and (FLoadBuffer<>nil) then
      begin
        bThreadRunning:=True;
        FLoadBuffer.Terminate;
      end;
      {if (FUseBuffer) and (bLoadingBuffer) then
      begin
        bThreadRunning:=True;
        FLoadBuffer.Terminate;
      end;}

      for i:=0 to nThumbnails-1 do
      begin
        //if FImgControl=icImgEdit then
        //if TShareImgThumbnail(FThumbList[i]).ImgEditCtrl.Image<>'' then
        begin
          TShareImgThumbnail(FThumbList[i]).Clear;
          if FShowPart then
            TShareImgThumbnail(FPartList[i]).Clear;
        end;
        try
          if (nThumbnails)*(FCurrentPage-1)+i<FImgList.Count then
          begin
            if (FUseBuffer) and (bThreadRunning) then
            begin
              //showmessage('threadruning');
              TShareImgThumbnail(FThumbList[i]).ImgFileName:=FImgList[(nThumbnails)*(FCurrentPage-1)+i];
            end
            else
            begin
              if (FUseBuffer) and (FImgControl=icImagXPress) then
              begin
                {if FPanelPreBuffer.Tag=FCurrentPage then
                  TShareImgThumbnail(FThumbList[i]).SethDib(TImagXPress(FPreBufferList[i]).CopyDIB,FImgList[(nThumbnails)*(FCurrentPage-1)+i])
                else if FPanelNextBuffer.Tag=FCurrentPage then
                  TShareImgThumbnail(FThumbList[i]).SethDib(TImagXPress(FNextBufferList[i]).CopyDIB,FImgList[(nThumbnails)*(FCurrentPage-1)+i])
                else
                  TShareImgThumbnail(FThumbList[i]).ImgFileName:=FImgList[(nThumbnails)*(FCurrentPage-1)+i]; }
                if TImagXPress(FPreBufferList[i]).Tag=FCurrentPage then
                  TShareImgThumbnail(FThumbList[i]).SethDib(TImagXPress(FPreBufferList[i]).CopyDIB,FImgList[(nThumbnails)*(FCurrentPage-1)+i])
                else if TImagXPress(FNextBufferList[i]).Tag=FCurrentPage then
                  TShareImgThumbnail(FThumbList[i]).SethDib(TImagXPress(FNextBufferList[i]).CopyDIB,FImgList[(nThumbnails)*(FCurrentPage-1)+i])
                else
                  TShareImgThumbnail(FThumbList[i]).ImgFileName:=FImgList[(nThumbnails)*(FCurrentPage-1)+i];
              end
              else
                TShareImgThumbnail(FThumbList[i]).ImgFileName:=FImgList[(nThumbnails)*(FCurrentPage-1)+i];
            end;
            
            if TShareImgThumbnail(FThumbList[i]).ImgFileName='' then
              TShareImgThumbnail(FThumbList[i]).LabelName:='';
            if FShowPart then
              TShareImgThumbnail(FPartList[i]).ImgFileName:=TShareImgThumbnail(FThumbList[i]).ImgFileName;
          end;
          if Assigned(FOnPageView) then
            FOnPageView(self,i,nThumbnails,(nThumbnails)*(FCurrentPage-1)+i);
        except
          on E:Exception do
          begin
            if Assigned(FOnOpenImageError) then
              FOnOpenImageError(self,'读取影像'+FImgList[(nThumbnails)*(FCurrentPage-1)+i]+'失败，错误信息：'+e.Message);
          end;
        end;
      end;
    finally
      if FUseBuffer then
        CreateImagebuffer;
        //FLoadBuffer:=TLoadBuffer.Create(false,self,self.FPanelPreBuffer,self.FPanelNextBuffer,self.FPreBufferList,self.FNextBufferList);
      if self.LockWindow then
        LockWindowUpdate(0);
      if FPageChanged then
        if Assigned(FOnPageChange) then
          FOnPageChange(self);
    end;
  end;
end;

procedure TShareIMGSlide.ViewImage(AImageName: string);
begin
  ViewImage(FImgList.IndexOf(AImageName));
end;

procedure TShareIMGSlide.ViewImage(AImageIndex: integer;RefreshPage:Boolean=False);
var
  i:integer;
  thumbIndex:integer;
begin
  if (AImageIndex<0) or (AImageIndex>=FImgList.Count) then
    Exit;
  for i:=1 to FPages do
  begin
    if AImageIndex<i*(nThumbnails) then
      break;
  end;
  if (i<>FCurrentPage) or (RefreshPage) then
    ViewPage(i);
  thumbIndex:=AImageIndex-(i-1)*(nThumbnails);
  //OnImgSelected(FThumbList[thumbIndex]);
  FSelectByMouse:=False;
  SelectThumbnail(FThumbList[thumbIndex]);
end;

procedure TShareIMGSlide.ResetSlideForm(ARow:integer=2; ACol:integer=3);
var
  i:integer;
  imgIndex:integer;
  bUseMag:Boolean;
  tmpViewMiddle:Boolean;
begin
  try
    if FViewMode=1 then exit;
    tmpViewMiddle:=self.FViewMiddleLine;
    SetMiddleLine(False);
    bUseMag:=self.FUseMagnifier;
    UseMagnifier:=False;
    imgIndex:=GetImageIndex;
    FRow:=ARow;
    FCol:=ACol;
    FThumbCreating:=True;
    for i:=FThumbList.Count-1 downto 0 do
    begin
      TShareImgThumbnail(FThumbList[i]).Free;
      if FShowPart then
        TShareImgThumbnail(FPartList[i]).Free;
    end;
    FThumbCreating:=False;
    FThumbList.Clear;
    CreateThumbnail(self);
    FThumbSelected:=nil;
    if FShowPart then
    begin
      FPartList.Clear;
      CreateThumbnail(FSbxPart);
      //
      SetSynColor(not self.FSynColor);
      SetSynColor(not self.FSynColor);
      SetSynLabelColor(not self.FSynLabelColor);
      SetSynLabelColor(not self.FSynLabelColor);
    end;
    FPages:=(FImgList.Count div FThumbList.Count);
    if FImgList.Count mod FThumbList.Count <>0 then
     Inc(FPages);

    if (imgIndex<0) or (imgIndex>=FImgList.Count) then
      imgIndex:=0;
    ViewImage(imgIndex,True);
  except
  end;
  UseMagnifier:=bUseMag;
  self.SetMiddleLine(tmpViewMiddle);
end;

procedure TShareIMGSlide.SetImgList(AImgList: TStringList);
begin
  FImgList.Clear;
  FImgList.Assign(AImgList);  //此处不能用等于，否则指针会出问题
  if FImgList.Count=0 then
  begin
    Clear;
    FPages:=1;
    Exit;
  end;
  FPages:=(FImgList.Count div FThumbList.Count);
  if FImgList.Count mod FThumbList.Count <>0 then
   Inc(FPages);
end;

procedure TShareIMGSlide.SetPopupMenu(pop: TPopupMenu);
var
  i:integer;
begin
  FPopupMenu:=pop;
  for i:=0 to nThumbnails-1 do
  begin
    TShareImgThumbnail(FThumbList[i]).SetPopupMenu(FPopupMenu);
    if self.FShowPart then
      TShareImgThumbnail(FPartList[i]).SetPopupMenu(FPopupMenu);
  end;
end;

function TShareIMGSlide.GetThumbByIndex(
  AIndex: Integer): TShareImgThumbnail;
begin
  result:=nil;
  if (AIndex>=0) and (AIndex<FThumbList.Count) then
    result:=FThumbList[AIndex]; 
end;

function TShareIMGSlide.GetThumbnailCount: integer;
begin
  result:=self.FThumbList.Count; //nThumbnails;
end;

procedure TShareIMGSlide.TimerEvent(Sender: TObject);
begin
  FTimer.Enabled:=False;
  if ReverseSlide then
    PriorPage
  else
    NextPage;
  if FStopped then
    Exit;
  if not ReverseSlide then
  begin
    if FCurrentPage<FPages then
      FTimer.Enabled:=True;
  end
  else
    if FCurrentPage>1 then
      FTimer.Enabled:=True;
end;

procedure TShareIMGSlide.StartSlide(AFromFirstPage:Boolean=False);
begin
  FStopped:=False;
  if AFromFirstPage then
    if FReverseSlide then
      LastPage
    else
      FirstPage;
  FTimer.Enabled:=True;
end;

procedure TShareIMGSlide.StopSlide;
begin
  FStopped:=True;
  FTimer.Enabled:=False;
end;

procedure TShareIMGSlide.SetThumbnailColor(AThumbIndex: Integer;
  AColor: TColor);
begin
  TShareImgThumbnail(FThumbList[AThumbIndex]).ForeGroundColor:=AColor;
  if FShowPart then
    if FSynColor then
      TShareImgThumbnail(FPartList[AThumbIndex]).ForeGroundColor:=AColor;
end;

procedure TShareIMGSlide.Refresh;
var
  oldPage:integer;
begin
  inherited;
  FPages:=(FImgList.Count div FThumbList.Count);
  if FImgList.Count mod FThumbList.Count <>0 then
   Inc(FPages);
  oldPage:=FCurrentPage;
  FCurrentPage:=-1;
  ViewPage(oldPage);
  FSelectByMouse:=False;
  SelectThumbnail(FThumbSelected);
end;

procedure TShareIMGSlide.SetRows(AValue: Integer);
begin
  if FViewMode=1 then exit;
  if FRow<>AValue then
  if AValue>0 then
  begin
    FRow:=AValue;
    self.ResetSlideForm(FRow,FCol);
    FlvKey.OnResize(self);
  end;
end;

procedure TShareIMGSlide.SetCols(AValue: Integer);
begin
  if FViewMode=1 then exit;
  if FCol<>AValue then
  if AValue>0 then
  begin
    FCol:=AValue;
    self.ResetSlideForm(FRow,FCol);
    FlvKey.OnResize(self);
  end;
end;

procedure TShareIMGSlide.SetThumbMargin(AValue: Integer);
begin
  if FThumbMargin<>AValue then
  if AValue>0 then
  begin
    FThumbMargin:=AValue;
    self.ResetSlideForm(FRow,FCol);
    FlvKey.OnResize(self);
  end;
end;

procedure TShareIMGSlide.SetTimeInterval(AValue: Integer);
begin
  if AValue>0 then
    FTimer.Interval:=AValue;
end;

procedure TShareIMGSlide.SetShowPart(AValue:Boolean);
var
  i:integer;
begin
  if FShowPart=AValue then
    Exit;
  FShowPart:=AValue;
  try
    if AValue then
    begin
      FPartList:=TList.Create;
      if FPartParent=nil then
        FPartParent:=self.Parent;
      FSbxPart.Parent:=FPartParent;
      FSbxPart.Align:=FPartAlign;
      //FSbxPart.OnResize:=ScrollBoxResize;
      FThumbCreating:=True;
      FSbxPart.Visible:=True;
      FThumbCreating:=False;
      FSbxPart.Enabled:=True;
      CreateThumbnail(FSbxPart);
      for i:=0 to FThumbList.Count-1 do
        TShareImgThumbnail(FPartList.Items[i]).ImgFileName:=TShareImgThumbnail(FThumbList.Items[i]).ImgFileName;
    end
    else
    begin
      for i:=0 to FThumbList.Count-1 do
      begin
        TShareImgThumbnail(FPartList.Items[i]).Clear;
        TShareImgThumbnail(FPartList.Items[i]).Free;
      end;
      FPartList.Free;
      FPartList:=nil;
      FSbxPart.Visible:=False;
    end;
  except
  end;
end;

procedure TShareIMGSlide.SetPartLabelVisible(AValue:Boolean);
var
  i:integer;
begin
  if FPartLabelVisible=AValue then
    Exit;
  FPartLabelVisible:=AValue;
  //如果不显示局部影像,那么赋值后不做界面处理
  if not FShowPart then
    Exit;
  try
    for i:=0 to FThumbList.Count-1 do
      TShareImgThumbnail(FPartList.Items[i]).LabelVisible:=AValue;
  except
  end;
end;

procedure TShareIMGSlide.SetPartAlign(AValue: TAlign);
begin
  if FPartAlign=AValue then
    Exit;
  FPartAlign:=AValue;
  if FShowPart then
    FSbxPart.Align:=AValue;
end;

procedure TShareIMGSlide.SetPartParent(AValue: TWinControl);
begin
  if FPartParent=AValue then
    Exit;
  FPartParent:=AValue;
  if FShowPart then
    FSbxPart.Parent:=AValue;
end;

procedure TShareIMGSlide.SetPartHeight(AValue: Integer);
begin
  if FPartHeight<>AValue then
    SetPartRect(FPartLeft,FPartTop,FPartWidth,AValue);
end;

procedure TShareIMGSlide.SetPartLeft(AValue: Integer);
begin
  if FPartLeft<>AValue then
    SetPartRect(AValue,FPartTop,FPartWidth,FPartHeight);
end;

procedure TShareIMGSlide.SetPartTop(AValue: Integer);
begin
  if FPartTop<>AValue then
    SetPartRect(FPartLeft,AValue,FPartWidth,FPartHeight);
end;

procedure TShareIMGSlide.SetPartWidth(AValue: Integer);
begin
  if FPartWidth<>AValue then
    SetPartRect(FPartLeft,FPartTop,AValue,FPartHeight);
end;

procedure TShareIMGSlide.SetPartRect(ALeft, ATop, AWidth,
  AHeight: Integer);
var
  i:integer;
begin
  FPartLeft:=ALeft;
  FPartTop:=ATop;
  FPartWidth:=AWidth;
  FPartHeight:=AHeight;
  if FShowPart then
    for i:=0 to nThumbnails-1 do
      TShareImgThumbnail(FPartList[i]).SetPartRect(FPartLeft,FPartTop,FPartWidth,FPartHeight);
end;

procedure TShareIMGSlide.SetPartRect(AthumbIndex, ALeft, ATop, AWidth,
  AHeight: Integer);
begin
  if FShowPart then
    if (AThumbIndex>=0) and (AThumbIndex<FPartList.Count) then
      TShareImgThumbnail(FPartList[AThumbIndex]).SetPartRect(ALeft,ATop,AWidth,AHeight);
end;

procedure TShareIMGSlide.SetPartThumbnailMargin(AValue: Integer);
var
  i:integer;
begin
  if (AValue<0) or (FPartThumbnailMargin=AValue) then
    Exit;
  FPartThumbnailMargin:=AValue;
  if FShowPart then
    for i:=0 to nThumbnails-1 do
      TShareImgThumbnail(FPartList[i]).ThumbnailMargin:=FPartThumbnailMargin;
end;

procedure TShareIMGSlide.Clear;
var
  i:integer;
begin
  for i:=0 to FThumbList.Count-1 do
  begin
    TShareImgThumbnail(FThumbList.Items[i]).Clear;
    if FShowPart then
      TShareImgThumbnail(FPartList.Items[i]).Clear;
  end;
  //FThumbList.Clear;
  //if FShowPart then
  //  FPartList.Clear;
  FImgList.Clear;
  FCurrentPage:=1;
  FPages:=1;
end;

procedure TShareIMGSlide.SetThumbnailPalette(AThumbIndex,
  APalette: integer);
begin
  TShareImgThumbnail(FThumbList[AThumbIndex]).ImagePalette:=APalette;
  if FShowPart then
    TShareImgThumbnail(FPartList[AThumbIndex]).ImagePalette:=APalette;
end;

procedure TShareIMGSlide.AddImage(AFileName: string;AHandle:THandle=0;ViewCurImg:Boolean=True);
var
  i:integer;
  bAddPosFound:Boolean;
begin
  try
    if self.LockWindow then
      LockWindowUpdate(self.Handle);
    FImgList.Add(AFileName);
    FPages:=(FImgList.Count div FThumbList.Count);
    if FImgList.Count mod FThumbList.Count <>0 then
      Inc(FPages);
    if not ViewCurImg then
      if FCurrentPage<FPages then
        Exit;
    if FCurrentPage<FPages then
    begin
      if FImgList.Count mod (nThumbnails) =1 then
      begin
        FCurrentPage:=FPages;
        for i:=0 to nThumbnails-1 do
        begin
          try
            if i=0 then
            begin
              if (AHandle=0) or (FImgControl=icImgEdit) then
              begin
                TShareImgThumbnail(FThumbList[0]).ImgFileName:=AFileName;
                if FShowPart then
                  TShareImgThumbnail(FPartList[0]).ImgFileName:=AFileName;
              end
              else
              begin
                TShareImgThumbnail(FThumbList[0]).SethDib(AHandle,AFileName);
                if FShowPart then
                  TShareImgThumbnail(FPartList[0]).SethDib(AHandle,AFileName);
              end;
              //OnImgSelected(TShareImgThumbnail(FThumbList[0]));
              FSelectByMouse:=False;
              SelectThumbnail(TShareImgThumbnail(FThumbList[0]));
            end
            else
            begin
              TShareImgThumbnail(FThumbList[i]).Clear;
              if FShowPart then
                TShareImgThumbnail(FPartList[i]).Clear;
            end;
            if ViewCurImg then
              if Assigned(FOnPageView) then
                FOnPageView(self,i,nThumbnails,(nThumbnails)*(FCurrentPage-1)+i);
          except
            on E:Exception do
            begin
              if Assigned(FOnOpenImageError) then
                FOnOpenImageError(self,'读取影像'+FImgList[(nThumbnails)*(FCurrentPage-1)+i]+'失败，错误信息：'+e.Message);
            end;
          end;
        end;

      end
      else
        ViewImage(FImgList.Count-1)
    end
    else
    begin
      bAddPosFound:=False;
      for i:=0 to nThumbnails-1 do
      begin
        if (TShareImgThumbnail(FThumbList[i]).ImgFileName='') and (not bAddPosFound) then
        begin
          try
            if (AHandle=0) or (FImgControl=icImgEdit) then
            begin
              TShareImgThumbnail(FThumbList[i]).ImgFileName:=AFileName;
              if FShowPart then
                TShareImgThumbnail(FPartList[i]).ImgFileName:=AFileName;
            end
            else
            begin
              TShareImgThumbnail(FThumbList[i]).SethDib(AHandle,AFileName);
              if FShowPart then
                TShareImgThumbnail(FPartList[i]).SethDib(AHandle,AFileName);
            end;
            //OnImgSelected(TShareImgThumbnail(FThumbList[i]));
            FSelectByMouse:=False;
            SelectThumbnail(TShareImgThumbnail(FThumbList[i]));
            //if ViewCurImg then
            //  if Assigned(FOnPageView) then
            //    FOnPageView(self,i,nThumbnails,(nThumbnails)*(FCurrentPage-1)+i);
          except
            on E:Exception do
            begin
              if Assigned(FOnOpenImageError) then
                FOnOpenImageError(self,'读取影像'+FImgList[(nThumbnails)*(FCurrentPage-1)+i]+'失败，错误信息：'+e.Message);
            end;
          end;
          //break;
          bAddPosFound:=True;
        end;
        if ViewCurImg then
          if Assigned(FOnPageView) then
            FOnPageView(self,i,nThumbnails,(nThumbnails)*(FCurrentPage-1)+i);
      end;
    end;
  finally
    if self.LockWindow then
      LockWindowUpdate(0);
    if self.FUseBuffer then
      self.CreateImagebuffer;  
  end;
end;

procedure TShareIMGSlide.DeleteImage(AImageIndex: Integer;ARefresh:Boolean=True);
var
  i:integer;
  ithumb,iPage:integer;
begin
  if (AImageIndex>=0) and (AImageIndex<FImgList.Count) then
  begin
    iPage:=(AImageIndex+1) div (nThumbnails);
    ithumb:=((AImageIndex+1) mod (nThumbnails))-1;
    if ithumb<0 then
      ithumb:=nThumbnails-1
    else
      iPage:=iPage+1;
    FImgList.Delete(AImageIndex);
    FPages:=(FImgList.Count div FThumbList.Count);
    if FImgList.Count mod FThumbList.Count <>0 then
     Inc(FPages);
    if (iPage<>FCurrentPage) or (not ARefresh) then    //如果删除的不是当前显示页那么不用更新显示
      Exit;
    try
      if self.LockWindow then
        LockwindowUpdate(self.handle);
      TShareImgThumbnail(FThumbList[ithumb]).Clear;
      if FShowPart then
        TShareImgThumbnail(FPartList[ithumb]).Clear;
      if FCurrentPage>FPages then
        ViewImage(FImgList.Count-1)
      else
      begin
        for i:=0{ithumb} to nThumbnails-1 do
        begin
          try
            if i>=iThumb then
            begin
              if i+(FCurrentPage-1)*nThumbnails<FImgList.Count then
              begin
                TShareImgThumbnail(FThumbList[i]).ImgFileName:=FImgList[i+(FCurrentPage-1)*nThumbnails];
                if FShowPart then
                  TShareImgThumbnail(FPartList[i]).ImgFileName:=FImgList[i+(FCurrentPage-1)*nThumbnails];
              end
              else
              begin
                TShareImgThumbnail(FThumbList[i]).Clear;
                if FShowPart then
                  TShareImgThumbnail(FPartList[i]).Clear;
              end;
            end;
            if ARefresh then
              if Assigned(FOnPageView) then
                FOnPageView(self,i,nThumbnails,(nThumbnails)*(FCurrentPage-1)+i);
          except
          end;
        end;
        if AImageIndex=FImgList.Count then  //说明删除的是最后一幅影像,那么就选中最后一幅影像，否则选择当前影像
          ithumb:=ithumb-1;
        //self.OnImgSelected(TShareImgThumbnail(FThumbList[ithumb]));
        FSelectByMouse:=False;
        SelectThumbnail(TShareImgThumbnail(FThumbList[ithumb]));
      end;
    finally
      if self.LockWindow then
        LockWindowUpdate(0);
      if self.FUseBuffer then
        self.CreateImagebuffer;
    end;
  end;
end;

procedure TShareIMGSlide.DeleteSelectImage;
begin
  self.DeleteImage(self.GetImageIndex);
end;

procedure TShareIMGSlide.InsertImage(AImageIndex: Integer;
  AFileName: string; ViewCurImg:Boolean=True);
var
  i:integer;
  ithumb,ipage:integer;
begin
  if AImageIndex<0 then AImageIndex:=0;
  if AImageIndex>=FImgList.Count then AImageIndex:=FImgList.Count;
  iPage:=(AImageIndex+1) div (nThumbnails);
  ithumb:=((AImageIndex+1) mod (nThumbnails))-1;
  if ithumb<0 then
    ithumb:=nThumbnails-1
  else
    iPage:=iPage+1;
  FImgList.Insert(AImageIndex,AFileName);
  FPages:=(FImgList.Count div FThumbList.Count);
  if FImgList.Count mod FThumbList.Count <>0 then
    Inc(FPages);
  if iPage<>FCurrentPage then  //如果不是插入到当前页
  begin
    if ViewCurImg then
      ViewImage(AImageIndex);
    Exit;
  end;
  try
    if self.LockWindow then
      LockWindowUpdate(self.Handle);
    if (FCurrentPage=FPages-1) and (AImageIndex=FImgList.Count-1) then  //如果插入的是最后一张并且增加了一页
      ViewImage(AImageIndex)
    else
    begin
      for i:=nThumbnails-1 downto 0 do// ithumb+1 do
      begin
        try
          if i>ithumb then
          begin
            TShareImgThumbnail(FThumbList[i]).ImgFileName:=TShareImgThumbnail(FThumblist[i-1]).ImgFileName;
            if TShareImgThumbnail(FThumbList[i]).ImgFileName='' then
              TShareImgThumbnail(FThumbList[i]).LabelName:='';
            if FShowPart then
              TShareImgThumbnail(FPartList[i]).ImgFileName:=TShareImgThumbnail(FPartList[i-1]).ImgFileName;
          end
          else if i=ithumb then
          begin
            try
              TShareImgThumbnail(FThumbList[ithumb]).ImgFileName:=AFileName;
              if TShareImgThumbnail(FThumbList[ithumb]).ImgFileName='' then
                TShareImgThumbnail(FThumbList[ithumb]).LabelName:='';
              if FShowPart then
                TShareImgThumbnail(FPartList[ithumb]).ImgFileName:=AFileName;
              //self.OnImgSelected(TShareImgThumbnail(FThumbList[ithumb]));
              FSelectByMouse:=False;
              SelectThumbnail(TShareImgThumbnail(FThumbList[ithumb]));
            except
            end;
          end;
          //if ViewCurImg then
            if Assigned(FOnPageView) then
              FOnPageView(self,i,nThumbnails,(nThumbnails)*(FCurrentPage-1)+i);
        except
          on E:Exception do
          begin
            if Assigned(FOnOpenImageError) then
              FOnOpenImageError(self,'读取影像'+FImgList[(nThumbnails)*(FCurrentPage-1)+i]+'失败，错误信息：'+e.Message);
          end;
        end;
      end;
    end;
  finally
    if self.LockWindow then
      LockWindowUpdate(0);
  end;
end;

procedure TShareIMGSlide.ReplaceImage(AImageIndex: Integer;
  AFileName: string; ViewCurImg: Boolean);
var
  i:integer;
  ithumb,iPage:integer;
begin
  if (AImageIndex>=0) and (AImageIndex<FImgList.Count) then
  begin
    iPage:=(AImageIndex+1) div (nThumbnails);
    ithumb:=((AImageIndex+1) mod (nThumbnails))-1;
    if ithumb<0 then
      ithumb:=nThumbnails-1
    else
      iPage:=iPage+1;
    FImgList[AImageIndex]:=AFileName;
    if not ViewCurImg then
    if (iPage<>FCurrentPage) then    //如果删除的不是当前显示页那么不用更新显示
      Exit;
    try
      if iPage<>FCurrentPage then
        ViewImage(AImageIndex,True)
      else
      begin
        if self.LockWindow then
          LockwindowUpdate(self.handle);
        try
          TShareImgThumbnail(FThumbList[ithumb]).ImgFileName:=AFileName;
          if FShowPart then
            TShareImgThumbnail(FPartList[ithumb]).ImgFileName:=AFileName;
          if AFileName='' then
            TShareImgThumbnail(FThumbList[ithumb]).LabelName:='';
        except
        end;
      end;
    finally
      if self.LockWindow then
        LockWindowUpdate(0);
    end;
  end;
end;

procedure TShareIMGSlide.SetMagnifier(AValue:Boolean);
var
  i:integer;
begin
  if FUseMagnifier=AValue then
    Exit;
  FUseMagnifier:=AValue;
  if AValue then
  begin
    if FImgControl=icImgEdit then
    begin
      for i:=0 to self.nThumbnails-1 do// nThumbnails-1 do
      begin
        TShareImgThumbnail(FThumbList[i]).ImgEditCtrl.OnEnter:=SetMagnifierImgEdit;
        TShareImgThumbnail(FThumbList[i]).ImgEditCtrl.Enabled:=True;
        if FShowPart then
        begin
          TShareImgThumbnail(FPartList[i]).ImgEditCtrl.OnEnter:=SetMagnifierImgEdit;
          TShareImgThumbnail(FPartList[i]).ImgEditCtrl.Enabled:=True;
        end;
      end;
    end
    else if FImgControl=icImagXPress then
    begin
      for i:=0 to self.nThumbnails-1 do// nThumbnails-1 do
      begin
        TShareImgThumbnail(FThumbList[i]).ImgXPressCtrl.Enabled:=True;
        if FUseXPressToolSetMagnifier then
        begin
          {$IFNDEF XPress6}
          TShareImgThumbnail(FThumbList[i]).ImgXPressCtrl.ToolSet(Tool_Mag,IXMOUSEBUTTON_Left,IXKEY_None);
          TShareImgThumbnail(FThumbList[i]).ImgXPressCtrl.ToolSetAttribute(Tool_Mag,TOOLATTR_MagWidth,200);
          TShareImgThumbnail(FThumbList[i]).ImgXPressCtrl.ToolSetAttribute(Tool_Mag,TOOLATTR_MagHeight,200);
          //放大镜中显示100%原始大小
          TShareImgThumbnail(FThumbList[i]).ImgXPressCtrl.ToolSetAttribute(Tool_Mag,TOOLATTR_MagFactor,Min(Trunc(100/TShareImgThumbnail(FThumbList[i]).ImgXPressCtrl.IPZoomF),1000));
          {$ENDIF}
        end
        else
          TShareImgThumbnail(FThumbList[i]).ImgXPressCtrl.OnEnter:=SetMagnifierImgEdit;
        //TShareImgThumbnail(FThumbList[i]).ImgXPressCtrl.OnEnter:=SetMagnifierImgEdit;
        if FShowPart then
        begin
          TShareImgThumbnail(FPartList[i]).ImgXPressCtrl.Enabled:=True;
          if FUseXPressToolSetMagnifier then
          begin
            {$IFNDEF XPress6}
            TShareImgThumbnail(FPartList[i]).ImgXPressCtrl.ToolSet(Tool_Mag,IXMOUSEBUTTON_Left,IXKEY_None);
            TShareImgThumbnail(FPartList[i]).ImgXPressCtrl.ToolSetAttribute(Tool_Mag,TOOLATTR_MagWidth,200);
            TShareImgThumbnail(FPartList[i]).ImgXPressCtrl.ToolSetAttribute(Tool_Mag,TOOLATTR_MagHeight,200);
            //放大镜中显示100%原始大小
            TShareImgThumbnail(FPartList[i]).ImgXPressCtrl.ToolSetAttribute(Tool_Mag,TOOLATTR_MagFactor,Min(Trunc(100/TShareImgThumbnail(FPartList[i]).ImgXPressCtrl.IPZoomF),1000));
            {$ENDIF}
          end
          else
            TShareImgThumbnail(FPartList[i]).ImgXPressCtrl.OnEnter:=SetMagnifierImgEdit;
          //TShareImgThumbnail(FPartList[i]).ImgXPressCtrl.OnEnter:=SetMagnifierImgEdit;
        end;
      end;
    end
    else if FImgControl=icImgShare then
    begin
      for i:=0 to self.nThumbnails-1 do// nThumbnails-1 do
      begin
        TShareImgThumbnail(FThumbList[i]).ImgShare.Enabled:=true;
        if FShowPart then
        begin
          TShareImgThumbnail(FPartList[i]).ImgShare.Enabled:=True;
        end;
      end;
    end;
  end
  else
  begin
    //FMagnifier.ImgControl:=nil;
    if FImgControl=icImgEdit then
    begin
      for i:=0 to nThumbnails-1 do
      begin
        TShareImgThumbnail(FThumbList[i]).ImgEditCtrl.OnEnter:=nil;
        TShareImgThumbnail(FThumbList[i]).ImgEditCtrl.OnMouseDown:=nil;
        TShareImgThumbnail(FThumbList[i]).ImgEditCtrl.OnMouseUp:=nil;
        TShareImgThumbnail(FThumbList[i]).ImgEditCtrl.OnMouseMove:=nil;
        TShareImgThumbnail(FThumbList[i]).ImgEditCtrl.Enabled:=False;
        if FShowPart then
        begin
          TShareImgThumbnail(FPartList[i]).ImgEditCtrl.OnEnter:=nil;
          TShareImgThumbnail(FPartList[i]).ImgEditCtrl.OnMouseDown:=nil;
          TShareImgThumbnail(FPartList[i]).ImgEditCtrl.OnMouseUp:=nil;
          TShareImgThumbnail(FPartList[i]).ImgEditCtrl.OnMouseMove:=nil;
          TShareImgThumbnail(FPartList[i]).ImgEditCtrl.Enabled:=False;
        end;
      end;
      FMagnifier.ImgEdit:=nil;
    end
    else if FImgControl=icImagXPress then
    begin
      for i:=0 to nThumbnails-1 do
      begin
        {$IFNDEF XPress6}
        TShareImgThumbnail(FThumbList[i]).ImgXPressCtrl.ToolSet(0,1,0);
        {$ENDIF}
        //TShareImgThumbnail(FThumbList[i]).ImgXPressCtrl.OnEnter:=nil;
        if FViewMode<>1 then
          TShareImgThumbnail(FThumbList[i]).ImgXPressCtrl.Enabled:=False;
        TShareImgThumbnail(FThumbList[i]).ImgXPressCtrl.OnEnter:=nil;
        if FShowPart then
        begin
          {$IFNDEF XPress6}
          TShareImgThumbnail(FPartList[i]).ImgXPressCtrl.ToolSet(0,1,0);
          {$ENDIF}
          //TShareImgThumbnail(FPartList[i]).ImgXPressCtrl.OnEnter:=nil;
          TShareImgThumbnail(FPartList[i]).ImgXPressCtrl.Enabled:=False;
          TShareImgThumbnail(FPartList[i]).ImgXPressCtrl.OnEnter:=nil;
        end;
        FXPressMagnifier.ImgEdit:=nil;
      end;
    end
    else if FImgControl=icImgShare then
    begin
      for i:=0 to nThumbnails-1 do
      begin
        TShareImgThumbnail(FThumbList[i]).ImgShare.Enabled:=False;
        if FShowPart then
        begin
          TShareImgThumbnail(FPartList[i]).ImgShare.Enabled:=False;
        end;
      end;
    end;
  end;
end;

procedure TShareIMGSlide.SetMagnifierImgEdit(Sender : TObject);
begin
  if Sender is TImgEdit then
    FMagnifier.ImgEdit:=TImgEdit(Sender)
  else if sender is TImagXPress then
    FXPressMagnifier.ImgEdit:=TImagXPress(Sender);
  //FMagnifier.ImgControl:=TWinControl(Sender);
end;

procedure TShareIMGSlide.OnPartImgSelected(Sender: TObject);
begin
  //showmessage('aa');
  self.SelectThumbnail(TShareImgThumbnail(FThumbList[FPartList.IndexOf(TShareImgThumbnail(Sender))]));//.SelectSelf(TShareImgThumbnail(FThumbList[FPartList.IndexOf(TShareImgThumbnail(Sender))]));
  //self.OnImgSelected(TShareImgThumbnail(FThumbList[FPartList.IndexOf(TShareImgThumbnail(Sender))]));//.SelectSelf(TShareImgThumbnail(FThumbList[FPartList.IndexOf(TShareImgThumbnail(Sender))]));
end;

procedure TShareIMGSlide.SetPartLabelName(Sender: TObject);
begin
  try
    if FShowPart then
      TShareImgThumbnail(FPartList[FThumbList.IndexOf(TShareImgThumbnail(Sender))]).LabelName:=TShareImgThumbnail(Sender).LabelName;
  except
  end;
end;

procedure TShareIMGSlide.SelectThumbnail(Sender: TObject);
begin
  try
    if Sender=nil then exit;
    self.OnImgSelected(Sender);
    if TShareImgThumbnail(Sender).Selected then
      if Assigned(FOnImgSelect) then
        FOnImgSelect(self,FSelectByMouse);
    FSelectByMouse:=True;
  except
  end;
end;

procedure TShareIMGSlide.SetFocus;
begin
  inherited;
  FlvKey.SetFocus;
end;

procedure TShareIMGSlide.SetSynLabelColor(Value: Boolean);
var
  i:integer;
begin
  if FSynLabelColor<>Value then
  begin
    FSynLabelColor:=Value;
    for i:=0 to FThumbList.Count-1 do
      if FSynLabelColor then
      begin
        TShareImgThumbnail(FThumbList[i]).OnSetLabelColor:=SetPartLabelColor;
        if FShowPart then
          TShareImgThumbnail(FPartList[i]).LabelColor:=TShareImgThumbnail(FThumbList[i]).LabelColor;
      end
      else
      begin
        TShareImgThumbnail(FThumbList[i]).OnSetLabelColor:=nil;
        if FShowPart then
          TShareImgThumbnail(FPartList[i]).SetDefaultLabelColor;
      end;
  end;
end;

procedure TShareIMGSlide.SetPartLabelColor(Sender: TObject);
begin
  try
    if FShowPart then
      TShareImgThumbnail(FPartList[FThumbList.IndexOf(TShareImgThumbnail(Sender))]).LabelColor:=TShareImgThumbnail(Sender).LabelColor;
  except
  end;
end;

procedure TShareIMGSlide.SetSynColor(Value: Boolean);
var
  i:integer;
begin
  if FSynColor<>Value then
  begin
    FSynColor:=Value;
    for i:=0 to FThumbList.Count-1 do
      if FSynColor then
      begin
        TShareImgThumbnail(FThumbList[i]).OnSetForeColor:=SetPartForeColor;
        if FShowPart then
          TShareImgThumbnail(FPartList[i]).ForeGroundColor:=TShareImgThumbnail(FThumbList[i]).ForeGroundColor;
      end
      else
      begin
        TShareImgThumbnail(FThumbList[i]).OnSetForeColor:=nil;
        if FShowPart then
          TShareImgThumbnail(FPartList[i]).ForeGroundColor:=clBtnFace;
      end;
  end;
end;

procedure TShareIMGSlide.SetPartForeColor(Sender: TObject);
begin
  try
    if FShowPart then
      TShareImgThumbnail(FPartList[FThumbList.IndexOf(TShareImgThumbnail(Sender))]).ForeGroundColor:=TShareImgThumbnail(Sender).ForeGroundColor;
  except
  end;
end;

procedure TShareIMGSlide.SetImgControl(AValue: TImgControl);
var
  i:integer;
begin
  if FImgControl=AValue then exit;
  if FViewMode=1 then exit;
  FImgControl:=AValue;
  for i:=0 to FThumbList.Count-1 do
  begin
    TShareImgThumbnail(FThumbList[i]).SetImgControl(AValue);
    if AValue=icImagXPress then
    begin
      TShareImgThumbnail(FThumbList[i]).ImgXPressCtrl.OnKeyDown:=self.OnlvKeyDown;
    end;
    if FShowPart then
    begin
      TShareImgThumbnail(FPartList[i]).SetImgControl(AValue);
      if AValue=icImagXPress then
        TShareImgThumbnail(FPartList[i]).ImgXPressCtrl.OnKeyDown:=self.OnlvKeyDown;
    end;
  end;
end;

procedure TShareIMGSlide.SetUseBuffer(Value: Boolean);
begin
  if FUseBuffer=Value then exit;
  FUseBuffer:=Value;
  if Value then
  begin
    self.CreateBufferImgControl;
    //FLoadBuffer:=TLoadBuffer.Create(false,self,self.FPanelPreBuffer,self.FPanelNextBuffer,self.FPreBufferList,self.FNextBufferList);
    self.CreateImagebuffer;
  end;
end;

procedure TShareIMGSlide.CreateBufferImgControl;
var
  i:integer;
  e:TImgEdit;
  x:TImagXPress;
  isl:TShareImgSlide;
begin
  isl:=self;
  for i:=FPanelPreBuffer.ControlCount-1 downto 0 do
    FPanelPreBuffer.Controls[i].Free;
  for i:=FPanelNextBuffer.ControlCount-1 downto 0 do
    FPanelNextBuffer.Controls[i].Free;
  FPreBufferList.Clear;
  FNextBufferList.Clear;
  for i:=0 to isl.Cols*isl.Rows-1 do
    if FImgControl=icImgEdit then
    begin
      e:=TImgEdit.Create(FPanelPreBuffer);
      e.Parent:=FPanelPreBuffer;
      FPreBufferList.Add(e);

      e:=TImgEdit.Create(FPanelNextBuffer);
      e.Parent:=FPanelNextBuffer;
      FNextBufferList.Add(e);
    end
    else if FImgControl=icImagXPress then
    begin
      x:=TImagXPress.Create(FPanelPreBuffer);
      //x.Parent:=FPanelPreBuffer;
      FPreBufferList.Add(x);

      x:=TImagXPress.Create(FPanelNextBuffer);
      //x.Parent:=FPanelNextBuffer;
      FNextBufferList.Add(x);
    end;
end;

procedure TShareIMGSlide.OnLoadBufferThreadTerminate(Sender: TObject);
begin
  Dec(nThreads);
  FLoadBuffer:=nil;
  //MessageBox(0,pChar('onterminate'),pChar('test'),mb_OK);
end;

{ TLoadBuffer }

constructor TLoadBuffer.Create(CreateSuspended: Boolean; ACon:TWincontrol;APreBufferpanel,ANextBufferPanel:TPanel;APreList,ANextList:TList);
begin
  Con:=ACon;
  FPanelPreBuffer:=APreBufferpanel;
  FPanelNextBuffer:=ANextBufferPanel;
  PreBufferList:=APreList;
  NextBufferList:=ANextList;
  inherited Create(CreateSuspended);
end;

{procedure TLoadBuffer.CreateImgControl(AImgControl: TImgControl);
var
  i:integer;
  e:TImgEdit;
  x:TImagXPress;
  isl:TShareImgSlide;
begin
  isl:=Con as  TShareImgSlide;
  FImgControl:=AImgControl;
  for i:=FPanelPreBuffer.ControlCount-1 downto 0 do
    FPanelPreBuffer.Controls[i].Free;
  for i:=FPanelNextBuffer.ControlCount-1 downto 0 do
    FPanelNextBuffer.Controls[i].Free;
  PreBufferList.Clear;
  NextBufferList.Clear;
  for i:=0 to isl.Cols*isl.Rows-1 do
    if AImgControl=icImgEdit then
    begin
      e:=TImgEdit.Create(FPanelPreBuffer);
      e.Parent:=FPanelPreBuffer;
      PreBufferList.Add(e);

      e:=TImgEdit.Create(FPanelNextBuffer);
      e.Parent:=FPanelNextBuffer;
      NextBufferList.Add(e);
    end
    else if AImgControl=icImagXPress then
    begin
      x:=TImagXPress.Create(FPanelPreBuffer);
      x.Parent:=FPanelPreBuffer;
      PreBufferList.Add(x);

      x:=TImagXPress.Create(FPanelNextBuffer);
      x.Parent:=FPanelNextBuffer;
      NextBufferList.Add(x);
    end;
end;   }

destructor TLoadBuffer.Destroy;
begin
//  if PreBufferList<>nil then
//    PreBufferList.Free;
//  if NextBufferList<>nil then
//    NextBufferList.Free;
  inherited;
end;

procedure TLoadBuffer.Execute;
begin
  inherited;
  FreeOnTerminate:=True;
  OnTerminate:=(Con as TShareImgSlide).OnLoadBufferThreadTerminate;
  FCurPage:=-1;
  Priority:=TThreadPriority(1);

  Inc((Con as TShareImgSlide).nThreads);
  FCurPage:=(Con as TShareImgSlide).CurPage;
  LoadBuffer;
{  bLoadingBuffer:=False;
  while not Terminated do
  begin
    if FCurPage<>(Con as TShareImgSlide).CurPage then
    begin
      //MessageBox(0,pChar('begin load buffer'),pChar('test'),mb_OK);
      //Synchronize(LoadBuffer);
      FCurPage:=(Con as TShareImgSlide).CurPage;
      LoadBuffer;
    end;
  end;}
end;

procedure TLoadBuffer.LoadBuffer;
var
  i:integer;
  isl:  TShareIMGSlide;
  strFile:string;
  t:integer;
begin
  //MessageBox(0,pChar('begin load buffer'),pChar('test'),mb_OK);
  t:=GettickCount;

  isl:=con as TShareIMGSlide;

  bLoadingBuffer:=True;

  if FCurPage>1 then
  begin
    FPanelPreBuffer.tag:=FCurPage-1;
    for i:=0 to isl.Cols*isl.Rows-1 do
    begin
      if Terminated then
      begin
//        MessageBox(0,pChar('terminate,  exit'),pChar('test'),mb_OK);
        Exit;
      end;

      if (FCurPage-2)*isl.Cols*isl.Rows+i<isl.ImageList.Count then
        strFile:=isl.ImageList[(FCurPage-2)*isl.Cols*isl.Rows+i]
      else
        strFile:='';

      if isl.ImgControl=icImgEdit then
      begin
        if strFile<>'' then
        begin
          TImgEdit(PreBufferList[i]).Image:=strFile;
          TImgEdit(PreBufferList[i]).Display;
        end
        else
          TImgEdit(PreBufferList[i]).ClearDisplay;
      end
      else if isl.ImgControl=icImagXPress then
      begin
        TImagXPress(PreBufferList[i]).FileName:=strFile;
      end;
    end;
  end
  else
    FPanelPreBuffer.tag:=-1;


  if FCurPage<isl.nPages then
  begin
    self.FPanelNextBuffer.Tag:=FCurPage+1;
    for i:=0 to isl.Cols*isl.Rows-1 do
    begin
      if Terminated then
      begin
//        MessageBox(0,pChar('terminate,  exit'),pChar('test'),mb_OK);
        Exit;
      end;

      if (FCurPage)*isl.Cols*isl.Rows+i<isl.ImageList.Count then
        strFile:=isl.ImageList[(FCurPage)*isl.Cols*isl.Rows+i]
      else
        strFile:='';

      if isl.ImgControl=icImgEdit then
      begin
        if strFile<>'' then
        begin
          TImgEdit(NextBufferList[i]).Image:=strFile;
          TImgEdit(NextBufferList[i]).Display;
        end
        else
          TImgEdit(NextBufferList[i]).ClearDisplay;
      end
      else if isl.ImgControl=icImagXPress then
      begin
        TImagXPress(NextBufferList[i]).FileName:=strFile;
      end;
    end;
  end
  else
    self.FPanelNextBuffer.Tag:=-1;

  bLoadingBuffer:=False;
  //MessageBox(0,pChar('end load buffer:  '+inttostr(GetTickCount-t)),pChar('test'),mb_OK);
end;

procedure TShareIMGSlide.SetMagParent(AValue: TWinControl);
begin
  FMagnifierParent:=AValue;
  FXPressMagnifier.Parent:=AValue;
end;

procedure TShareIMGSlide.SetXPressOwnMagnifier(Value: Boolean);
var
  b:Boolean;
begin
  b:=FUseMagnifier;
  if b then
    UseMagnifier:=False;
  FUseXPressToolSetMagnifier:=Value;
  if b then
    UseMagnifier:=True;
end;

procedure TShareIMGSlide.SetMiddleLine(Value: Boolean);
var
  i:integer;
begin
  if self.FViewMiddleLine=Value then exit;
  FViewMiddleLine:=Value;
  for i:=0 to self.nThumbnails-1 do
    TShareImgThumbnail(FThumbList[i]).ViewMiddleLine:=Value;
end;

procedure TShareIMGSlide.SetMiddleLineType(Value: integer);
var
  i:integer;
begin
  if self.FMiddleLineType=Value then exit;
  FMiddleLineType:=Value;
  for i:=0 to self.nThumbnails-1 do
    TShareImgThumbnail(FThumbList[i]).MiddleLineType:=Value;
end;

procedure TShareIMGSlide.ResizeAll;
begin
  if self.FShowPart then
    self.ScrollBoxResize(self.FSbxPart);
  self.ScrollBoxResize(self);
end;

procedure TShareIMGSlide.CreateImagebuffer;
var
  i:integer;
  tt:TViewBufferImage;
begin
  if self.FImgControl=icImagXPress then
  begin
    for i:=0 to self.nThumbnails-1 do
    begin
      tt:=TViewBufferImage.Create(self,TImagXPress(FPreBufferList[i]),1,i,self.FCurrentPage);
      tt:=TViewBufferImage.Create(self,TImagXPress(FNextBufferList[i]),2,i,self.FCurrentPage);
    end;
  end;
end;

procedure TShareIMGSlide.SetLabelAlign(Value: TLabelAlign);
var
  i:integer;
begin
  if self.FLabelAlign=Value then
    Exit;
  FLabelAlign:=Value;
  //如果不显示局部影像,那么赋值后不做界面处理
  try
    for i:=0 to FThumbList.Count-1 do
    begin
      TShareImgThumbnail(FThumbList.Items[i]).LabelAlign:=Value;
      if self.FShowPart then
        TShareImgThumbnail(FPartList.Items[i]).LabelAlign:=Value;
    end;
  except
  end;
end;

procedure TShareIMGSlide.SetViewMode(AViewMode: integer);
begin
  //只针对XPress做这些操作
  if self.ImgControl<>icImagXPress then exit;
  if AViewMode=FViewMode then exit;
  if AViewMode=1 then
  begin
    self.ResetSlideForm(1,1);
    self.ThumbnailList[0].SetViewMode(AViewMode);
    self.ThumbnailList[0].ImgXPressCtrl.Enabled:=True;
    self.ThumbnailList[0].ImgXPressCtrl.OnKeyDown:= OnlvKeyDown;
  end
  else
    self.ThumbnailList[0].ImgXPressCtrl.Enabled:=self.UseMagnifier;
  FViewMode:=AViewMode;
end;

end.
