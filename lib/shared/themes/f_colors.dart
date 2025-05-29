// ignore_for_file: unused_field

import 'package:flutter/material.dart';

class FColors {
  static final FColors _instance = FColors._();

  factory FColors() => _instance;

  FColors._();

  static bool _isBrightTheme = false;

  static bool get isBrightTheme => _isBrightTheme;

  static FColors of(BuildContext context) {
    _isBrightTheme = Theme.of(context).brightness == Brightness.light;
    return _instance;
  }

  static FColors get current {
    return _instance;
  }

  // brand
  Color get fiet => _isBrightTheme ? _lightFiet : _darkFiet;

  Color get mvm => _isBrightTheme ? _lightMVM : _darkMVM;

  Color get fietFitness => _isBrightTheme ? const Color(0xFF37FF00) : const Color(0XFF37FF00);

  // palette global
  Color get white => _white;

  Color get black => _black;

  Color get yellow => _isBrightTheme ? const Color(0xFFF7CF00) : const Color(0XFFFFD900);

  Color get lightGreen => _lightGreen;

  //background
  Color get backgroundNormalN => _isBrightTheme ? _lightNormalN : _darkNormalN;

  Color get backgroundNormalA => _isBrightTheme ? _lightNormalA : _darkNormalA;

  Color get backgroundAlternativeN => _isBrightTheme ? _lightAlternativeN : _darkAlternativeN;

  Color get backgroundAlternativeA => _isBrightTheme ? _lightAlternativeA : _darkAlternativeA;

  Color get backgroundElevatedNormal => _isBrightTheme ? _white : _gray20;

  Color get lightNormalN => _lightNormalN;

  Color get darkNormalN => _darkNormalN;

  //label
  Color get labelStrong => _isBrightTheme ? _lightLabelStrong : _darkLabelStrong;

  Color get labelNormal => _isBrightTheme ? _lightLabelNormal : _darkLabelNormal;

  Color get labelNeutral => _isBrightTheme ? _lightLabelNeutral : _darkLabelNeutral;

  Color get labelAlternative => _isBrightTheme ? _lightLabelAlternative : _darkLabelAlternative;

  Color get labelAssistive => _isBrightTheme ? _lightLabelAssistive : _darkLabelAssistive;

  Color get labelDisable => _isBrightTheme ? _lightLabelDisable : _darkLabelDisable;

  //solid
  Color get solidStrong => _isBrightTheme ? _lightSolidStrong : _darkSolidStrong;

  Color get solidNormal => _isBrightTheme ? _lightSolidNormal : _darkSolidNormal;

  Color get solidNeutral => _isBrightTheme ? _lightSolidNeutral : _darkSolidNeutral;

  Color get solidAlternative => _isBrightTheme ? _lightSolidAlternative : _darkSolidAlternative;

  Color get solidAssistive => _isBrightTheme ? _lightSolidAssistive : _darkSolidAssistive;

  Color get solidDisable => _isBrightTheme ? _lightSolidDisable : _darkSolidDisable;

  //lines
  Color get lineStrong => _isBrightTheme ? _lightLineStrong : _darkLineStrong;

  Color get lineNormal => _isBrightTheme ? _lightLineNormal : _darkLineNormal;

  Color get lineAlternative => _isBrightTheme ? _lightLineAlternative : _darkLineAlternative;

  Color get lineAssistive => _isBrightTheme ? _lightLineAssistive : _darkLineAssistive;

  Color get lineNeutral => _isBrightTheme ? _lightLabelDisable : _darkLabelDisable;

  Color get lineSubtle => _isBrightTheme ? _lightLineSubtle : _darkLineSubtle;

  //status
  Color get statusPositive => _isBrightTheme ? _lightStatusPositive : _darkStatusPositive;

  Color get statusCautionary => _isBrightTheme ? _lightStatusCautionary : _darkStatusCautionary;

  Color get statusNegative => _isBrightTheme ? _lightStatusNegative : _darkStatusNegative;

  //alpha
  Color get alphaNormalAlpha7 =>
      _isBrightTheme ? _darkInverseStrong.withValues(alpha: .7) : _lightInverseStrong.withValues(alpha: .7);

  //state
  Color get colorRed => _isBrightTheme ? _lightRed : _darkRed;

  Color get colorOrange => _isBrightTheme ? _lightOrange : _darkOrange;

  Color get colorYellow => _isBrightTheme ? _lightYellow : _darkYellow;

  Color get colorLime => _isBrightTheme ? _lightLime : _darkLime;

  Color get colorGreen => _isBrightTheme ? _lightGreen : _darkGreen;

  Color get colorSky => _isBrightTheme ? _lightSky : _darkSky;

  Color get colorBlue => _isBrightTheme ? _lightBlue : _darkBlue;

  Color get colorViolet => _isBrightTheme ? _lightViolet : _darkViolet;

  Color get colorPurple => _isBrightTheme ? _lightPurple : _darkPurple;

  Color get blue99 => _blue99;

  Color get blue60 => _blue60;

  Color get sky99 => _sky99;

  Color get sky90 => _sky90;

  Color get sky40 => _sky40;

  Color get purple99 => _purple99;

  Color get orange30 => _orange30;

  Color get orange40 => _orange40;

  Color get orange99 => _orange99;

  Color get red => _red40;

  Color get red30 => _red30;

  Color get red80 => _red80;

  Color get red99 => _red99;

  Color get green30 => _green30;

  Color get green99 => _green99;

  Color get green => _green40;

  Color get lime30 => _lime30;

  Color get lime40 => _lime40;

  Color get lime99 => _lime99;

  Color get blue80 => _blue80;

  Color get purple80 => _purple80;

  Color get orange80 => _orange80;

  Color get orange60 => _orange60;

  Color get violet70 => _violet70;

  Color get green80 => _green80;

  //inverse
  Color get inverseStrong => _isBrightTheme ? _lightInverseStrong : _darkInverseStrong;

  Color get inverseNormal => _isBrightTheme ? _lightInverseNormal : _darkInverseNormal;

  Color get inverseAlternative => _isBrightTheme ? _lightInverseAlternative : _darkInverseAlternative;

  Color get inverseAssistive => _isBrightTheme ? _lightInverseAssistive : _darkInverseAssistive;

  Color get inverseSubtle => _isBrightTheme ? _lightInverseSubtle : _darkInverseSubtle;

  final _blue05 = const Color(0xFF00093D);
  final _blue10 = const Color(0xFF031253);
  final _blue20 = const Color(0xFF0C2471);
  final _blue30 = const Color(0xFF173690);
  final _blue40 = const Color(0xFF2047AD);
  final _blue50 = const Color(0xFF2A59CC);
  final _blue60 = const Color(0xFF346BEA);
  final _blue70 = const Color(0xFF6B92F0);
  final _blue80 = const Color(0xFF9EB6F5);
  final _blue90 = const Color(0xFFD1DAFA);
  final _blue99 = const Color(0xFFEBEFFD);
  final _common00 = const Color(0xFF000000);
  final _common100 = const Color(0xFFFFFFFF);
  final _fietGreen05 = const Color(0xFF003020);
  final _fietGreen10 = const Color(0xFF014630);
  final _fietGreen15 = const Color(0xFF006644);
  final _fietGreen20 = const Color(0xFF008559);
  final _fietGreen30 = const Color(0xFF00AC72);
  final _fietGreen40 = const Color(0xFF00DC93);
  final _fietGreen50 = const Color(0xFF00F2A1);
  final _fietGreen60 = const Color(0xFF54F6C0);
  final _fietGreen70 = const Color(0xFF8AF9D4);
  final _fietGreen80 = const Color(0xFFB0FBE2);
  final _fietGreen90 = const Color(0xFFCCFCEC);
  final _fietGreen95 = const Color(0xFFE6FEF6);
  final _fietGreen99 = const Color(0xFFF3FFFB);
  final _gray05 = const Color(0xFF080808);
  final _gray10 = const Color(0xFF111113);
  final _gray15 = const Color(0xFF141416);
  final _gray20 = const Color(0xFF171719);
  final _gray25 = const Color(0xFF1C1C1F);
  final _gray30 = const Color(0xFF212125);
  final _gray35 = const Color(0xFF2C2C30);
  final _gray40 = const Color(0xFF3A3A3F);
  final _gray45 = const Color(0xFF48484E);
  final _gray50 = const Color(0xFF5C5C64);
  final _gray55 = const Color(0xFF73737C);
  final _gray60 = const Color(0xFF8A8A91);
  final _gray65 = const Color(0xFF96969D);
  final _gray70 = const Color(0xFFB1B1B6);
  final _gray75 = const Color(0xFFC3C3C8);
  final _gray80 = const Color(0xFFDBDBDF);
  final _gray85 = const Color(0xFFE3E3E7);
  final _gray90 = const Color(0xFFEBEBEF);
  final _gray95 = const Color(0xFFF2F2F5);
  final _gray99 = const Color(0xFFF6F6F9);
  final _green05 = const Color(0xFF003B0F);
  final _green10 = const Color(0xFF145825);
  final _green20 = const Color(0xFF1A7330);
  final _green30 = const Color(0xFF22943E);
  final _green40 = const Color(0xFF2CBE50);
  final _green50 = const Color(0xFF30D158);
  final _green60 = const Color(0xFF59DA79);
  final _green70 = const Color(0xFF74E08F);
  final _green80 = const Color(0xFFA0EAB2);
  final _green90 = const Color(0xFFD9FFE6);
  final _green95 = const Color(0xFFD9FFE6);
  final _green99 = const Color(0xFFEFFFF5);
  final _lime05 = const Color(0xFF333B00);
  final _lime10 = const Color(0xFF546200);
  final _lime20 = const Color(0xFF6F8100);
  final _lime30 = const Color(0xFF8FA600);
  final _lime40 = const Color(0xFFB7D500);
  final _lime50 = const Color(0xFFC9EA00);
  final _lime60 = const Color(0xFFD4EE33);
  final _lime70 = const Color(0xFFDBF154);
  final _lime80 = const Color(0xFFE6F58A);
  final _lime90 = const Color(0xFFEEF8B0);
  final _lime99 = const Color(0xFFFAFDE6);
  final _yellow05 = const Color(0xFF4C4100); //#4C4100
  final _yellow10 = const Color(0xFF6B5B00); //#6B5B00
  final _yellow20 = const Color(0xFF6B5B00); //#6B5B00
  final _yellow30 = const Color(0xFFB59A00); //#B59A00
  final _yellow40 = const Color(0xFFF7CF00); //#F7CF00
  final _yellow50 = const Color(0xFFFFD900); //#FFD900
  final _yellow60 = const Color(0xFFFFE133); //#FFE133
  final _yellow70 = const Color(0xFFFFE654); //#FFE654
  final _yellow80 = const Color(0xFFFFEE8A); //#FFEE8A
  final _yellow90 = const Color(0xFFFFF3B0); //#FFF3B0
  final _yellow99 = const Color(0xFFFFFBE6);
  final _orange5 = const Color(0xFF402301);
  final _orange10 = const Color(0xFF6D3B00);
  final _orange20 = const Color(0xFF914E00);
  final _orange30 = const Color(0xFFC27400);
  final _orange40 = const Color(0xFFEE9100);
  final _orange50 = const Color(0xFFFF9F0A);
  final _orange60 = const Color(0xFFFFB23B);
  final _orange70 = const Color(0xFFFFBF5B);
  final _orange80 = const Color(0xFFFFD38E);
  final _orange90 = const Color(0xFFFFE1B3);
  final _orange99 = const Color(0xFFFFF5E7);
  final _purple05 = const Color(0xFF2D0042);
  final _purple10 = const Color(0xFF49006B);
  final _purple20 = const Color(0xFF5F008C);
  final _purple30 = const Color(0xFF7B00B5);
  final _purple40 = const Color(0xFF9700E0);
  final _purple50 = const Color(0xFFAD00FF);
  final _purple60 = const Color(0xFFC141FF);
  final _purple70 = const Color(0xFFD376FF);
  final _purple80 = const Color(0xFFDD97FF);
  final _purple90 = const Color(0xFFF0CFFF);
  final _purple99 = const Color(0xFFFAEFFF);
  final _red05 = const Color(0xFF450804);
  final _red10 = const Color(0xFF6B1D18);
  final _red20 = const Color(0xFF8C2620);
  final _red30 = const Color(0xFFB53129);
  final _red40 = const Color(0xFFE83F35);
  final _red50 = const Color(0xFFFF453A);
  final _red60 = const Color(0xFFFF6A61);
  final _red70 = const Color(0xFFFF827B);
  final _red80 = const Color(0xFFFFA9A4);
  final _red90 = const Color(0xFFFFC5C2);
  final _red99 = const Color(0xFFFFECEB);
  final _sky05 = const Color(0xFF002A42);
  final _sky10 = const Color(0xFF00446B);
  final _sky20 = const Color(0xFF005A8C);
  final _sky30 = const Color(0xFF0074B5);
  final _sky40 = const Color(0xFF0094E8);
  final _sky50 = const Color(0xFF00A3FF);
  final _sky60 = const Color(0xFF33B5FF);
  final _sky70 = const Color(0xFF54C1FF);
  final _sky80 = const Color(0xFF8AD5FF);
  final _sky90 = const Color(0xFFB0E2FF);
  final _sky99 = const Color(0xFFE6F6FF);
  final _violet05 = const Color(0xFF170040);
  final _violet10 = const Color(0xFF29006B);
  final _violet20 = const Color(0xFF35008C);
  final _violet30 = const Color(0xFF4500B5);
  final _violet40 = const Color(0xFF5700E6);
  final _violet50 = const Color(0xFF6A0FFF);
  final _violet60 = const Color(0xFF7A3AFF);
  final _violet70 = const Color(0xFF925FFF);
  final _violet80 = const Color(0xFFB796FF);
  final _violet90 = const Color(0xFFDECFFF);
  final _violet95 = const Color(0xFFF0ECFE);
  final _violet99 = const Color(0xFFF0ECFE);

  //  bool get _isBrightTheme {
  //   return MvmKey.rootNavigation.currentContext?.isBrightness ?? true;
  // }

  Color get _lightFiet => _fietGreen40;

  Color get _darkFiet => _fietGreen50;
  final Color _lightMVM = const Color(0xFFA9E600);
  final Color _darkMVM = const Color(0xFFC3FF1D);

  Color get _white => _common100;

  Color get _black => _common00;

  Color get _lightNormalN => _common100;

  Color get _lightNormalA => _gray99;

  Color get _lightAlternativeN => _common100;

  Color get _lightAlternativeA => _gray99;

  Color get _darkNormalN => _gray10;

  Color get _darkNormalA => _gray05;

  Color get _darkAlternativeN => _gray45;

  Color get _darkAlternativeA => _gray30;

  Color get _lightLabelStrong => _gray05;

  Color get _lightLabelNormal => _gray20;

  Color get _lightLabelNeutral => _gray45;

  Color get _lightLabelAlternative => _gray60;

  Color get _lightLabelAssistive => _gray70;

  Color get _lightLabelDisable => _gray75;

  Color get _darkLabelStrong => _common100;

  Color get _darkLabelNormal => _gray99;

  Color get _darkLabelNeutral => _gray70;

  Color get _darkLabelAlternative => _gray60;

  Color get _darkLabelAssistive => _gray55;

  Color get _darkLabelDisable => _gray50;

  Color get _lightSolidStrong => _gray10;

  Color get _lightSolidNormal => _gray40;

  Color get _lightSolidNeutral => _gray60;

  Color get _lightSolidAlternative => _gray80;

  Color get _lightSolidAssistive => _gray99;

  Color get _lightSolidDisable => _gray95;

  Color get _lightLineSubtle => _gray95;

  Color get _darkSolidStrong => _common100;

  Color get _darkSolidNormal => _gray70;

  Color get _darkSolidNeutral => _gray60;

  Color get _darkSolidAlternative => _gray45;

  Color get _darkSolidAssistive => _gray30;

  Color get _darkSolidDisable => _gray35;

  Color get _lightLineStrong => _common00;

  Color get _lightLineNormal => _gray40;

  Color get _lightLineAlternative => _gray80;

  Color get _lightLineAssistive => _gray90;

  Color get _darkLineStrong => _common100;

  Color get _darkLineNormal => _gray80;

  Color get _darkLineAlternative => _gray45;

  Color get _darkLineAssistive => _gray35;

  Color get _darkLineSubtle => _gray20;

  Color get _lightStatusPositive => _green40;

  Color get _lightStatusCautionary => _orange40;

  Color get _lightStatusNegative => _red40;

  Color get _darkStatusPositive => _green50;

  Color get _darkStatusCautionary => _orange50;

  Color get _darkStatusNegative => _red50;

  Color get _lightRed => _red40;

  Color get _lightOrange => _orange40;

  Color get _lightYellow => _yellow40;

  Color get _lightLime => _lime40;

  Color get _lightGreen => _green40;

  Color get _lightSky => _sky40;

  Color get _lightBlue => _blue40;

  Color get _lightViolet => _violet40;

  Color get _lightPurple => _purple40;

  Color get _darkRed => _red50;

  Color get _darkOrange => _orange50;

  Color get _darkYellow => _yellow50;

  Color get _darkLime => _lime50;

  Color get _darkGreen => _green50;

  Color get _darkSky => _sky50;

  Color get _darkBlue => _blue50;

  Color get _darkViolet => _violet50;

  Color get _darkPurple => _purple50;

  Color get _lightInverseStrong => _common100;

  Color get _lightInverseNormal => _gray99;

  Color get _lightInverseAlternative => _gray90;

  Color get _lightInverseAssistive => _gray70;

  Color get _lightInverseSubtle => _gray60;

  Color get _darkInverseStrong => _common00;

  Color get _darkInverseNormal => _gray20;

  Color get _darkInverseAlternative => _gray25;

  Color get _darkInverseAssistive => _gray40;

  Color get _darkInverseSubtle => _gray55;
}
