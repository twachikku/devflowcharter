{
   Copyright � 2007 Frost666, The devFlowcharter project.
   The initial author of this file is Michal Domagala.
   
   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
}

unit Return_Block;

interface

uses
   Vcl.Graphics, System.Classes, Vcl.StdCtrls, Base_Block, CommonInterfaces;

type

   TReturnBlock = class(TBlock)
      public
         constructor Create(const ABranch: TBranch); overload;
         constructor Create(const ABranch: TBranch; const ALeft, ATop, AWidth, AHeight: integer; const AId: integer = ID_INVALID); overload;
         function Clone(const ABranch: TBranch): TBlock; override;
         function GenerateCode(const ALines: TStringList; const ALangId: string; const ADeep: integer; const AFromLine: integer = LAST_LINE): integer; override;
         procedure ChangeColor(const AColor: TColor); override;
         procedure UpdateEditor(AEdit: TCustomEdit); override;
         function GetDescription: string; override;
      protected
         FReturnLabel: string;
         procedure Paint; override;
         procedure MyOnMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer); override;
         function GetDefaultWidth: integer;
   end;

implementation

uses
   Vcl.Controls, System.SysUtils, WinApi.Windows, System.StrUtils, System.Types,
   System.UITypes, ApplicationCommon, Project, UserFunction, Main_Block, CommonTypes;

constructor TReturnBlock.Create(const ABranch: TBranch; const ALeft, ATop, AWidth, AHeight: integer; const AId: integer = ID_INVALID);
var
   defWidth: integer;
begin

   FType := blReturn;

   inherited Create(ABranch, ALeft, ATop, AWidth, AHeight, AId);

   FReturnLabel := i18Manager.GetString('CaptionExit');

   defWidth := GetDefaultWidth;
   if defWidth > Width then
      Width := defWidth;

   FStatement.SetBounds((Width div 2)-26, 31, 52, 19);
   FStatement.Anchors := [akRight, akLeft, akTop];
   FStatement.Alignment := taCenter;

   BottomPoint.X := Width div 2;
   BottomPoint.Y := 19;
   IPoint.X := BottomPoint.X + 30;
   IPoint.Y := 30;
   BottomHook := BottomPoint.X;
   TopHook.X := BottomPoint.X;
end;

function TReturnBlock.Clone(const ABranch: TBranch): TBlock;
begin
   result := TReturnBlock.Create(ABranch, Left, Top, Width, Height);
   result.CloneFrom(Self);
end;

constructor TReturnBlock.Create(const ABranch: TBranch);
begin
   Create(ABranch, 0, 0, 140, 53);
end;

procedure TReturnBlock.Paint;
var
   fontStyles: TFontStyles;
   R: TRect;
begin
   inherited;
   fontStyles := Canvas.Font.Style;
   Canvas.Font.Style := [];
   R := DrawEllipsedText(Point(Width div 2, 30), FReturnLabel);
   DrawBlockLabel(R.Left, R.Bottom, GInfra.CurrentLang.LabelReturn, true);
   Canvas.Font.Style := fontStyles;
   DrawI;
end;

function TReturnBlock.GetDefaultWidth: integer;
var
   R: TRect;
begin
   R := GetEllipseTextRect(Point(0, 0), FReturnLabel);
   result := R.Right - R.Left + 48;
end;

function TReturnBlock.GenerateCode(const ALines: TStringList; const ALangId: string; const ADeep: integer; const AFromLine: integer = LAST_LINE): integer;
var
   indnt, expr: string;
   iter: IIterator;
   func: TUserFunction;
   inFunc: boolean;
   tmpList: TStringList;
begin
   result := 0;
   if fsStrikeOut in Font.Style then
      exit;
   if ALangId = PASCAL_LANG_ID then
   begin
      indnt := DupeString(GSettings.IndentString, ADeep);
      expr := Trim(FStatement.Text);
      inFunc := false;
      if expr <> '' then
      begin
         iter := GProject.GetUserFunctions;
         while iter.HasNext do
         begin
            func := TUserFunction(iter.Next);
            inFunc := func.Active and (func.Body = FTopParentBlock) and (func.Header <> nil) and (func.Header.cbType.ItemIndex > 0);
            if inFunc then
               break;
         end;
      end;
      tmpList := TStringList.Create;
      try
         if inFunc then
            tmpList.AddObject(indnt + func.Header.edtName.Text + ' ' + GInfra.GetLangDefinition(ALangId).AssignOperator + ' ' + expr + ';', Self);
         if not ((TMainBlock(FTopParentBlock).GetBranch(PRIMARY_BRANCH_IND).Last = Self) and inFunc) then
            tmpList.AddObject(indnt + 'exit;', Self);
         TInfra.InsertLinesIntoList(ALines, tmpList, AFromLine);
         result := tmpList.Count;
      finally
         tmpList.Free;
      end;
   end
   else
      result := inherited GenerateCode(ALines, ALangId, ADeep, AFromLine);
end;

procedure TReturnBlock.UpdateEditor(AEdit: TCustomEdit);
var
   chLine: TChangeLine;
   list: TStringList;
begin
   if PerformEditorUpdate then
   begin
      chLine := TInfra.GetChangeLine(Self, FStatement);
      if chLine.Row <> ROW_NOT_FOUND then
      begin
         list := TStringList.Create;
         try
            GenerateCode(list, GInfra.CurrentLang.Name, 0);
            chLine.Text := TInfra.ExtractIndentString(chLine.Text) + list.Text;
         finally
            list.Free;
         end;
         if GSettings.UpdateEditor and not SkipUpdateEditor then
            TInfra.ChangeLine(chLine);
         TInfra.GetEditorForm.SetCaretPos(chLine);
      end;
   end;
end;

procedure TReturnBlock.ChangeColor(const AColor: TColor);
begin
   inherited ChangeColor(AColor);
   FStatement.Color := AColor;
end;

procedure TReturnBlock.MyOnMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
   SelectBlock(Point(X, Y));
end;

function TReturnBlock.GetDescription: string;
begin
   if GInfra.CurrentLang.ReturnDesc <> '' then
      result := ReplaceStr(GInfra.CurrentLang.ReturnDesc, PRIMARY_PLACEHOLDER, Trim(FStatement.Text))
   else
      result := inherited GetDescription;
end;


end.
