# OverlayPlugin

## �r���h���@

�� �����[�X�y�[�W�Ńr���h�ς݂̃o�C�i����z�z���Ă��܂��̂ŁA�ʓ|�ȕ��͂���������g�����������B

�菇:

* .NET Framework 4.5.1 ���C���X�g�[�����܂�
* Microsoft Build Tools 2013 (http://www.microsoft.com/ja-jp/download/details.aspx?id=40760) ���C���X�g�[�����܂��iVisual Studio 2013 ���C���X�g�[������Ă���ꍇ�͕s�v�j
* �\�[�X�R�[�h�ꎮ���`�F�b�N�A�E�g�A�܂��� ZIP �t�@�C���Ń_�E�����[�h���ĉ𓀂��܂�
* Thirdparty �t�H���_�̒��ɂ��� ACT �t�H���_�ɁAACT �̎��s�t�@�C���iAdvanced Combat Tracker.exe�j���R�s�[���܂�
* build.bat �����s���܂�

���܂������΁ABuild �t�H���_�̒��Ƀv���O�C������������܂��B

## �g�p���@

OverlayPlugin.dll ���v���O�C���Ƃ��� ACT �ɒǉ����܂��B
OverlayPlugin.dll �P�̂𔲂��o���Ă̎g�p�͂ł��܂���B���̃t�H���_�Ɉڂ������Ƃ��́A�ق��̑S�Ẵt�@�C���ƈꏏ�Ɉړ������Ă��������B

�ǉ�����ƁA�uNo data to show�v�A�܂��� DPS ���\�����ꂽ�E�B���h�E���\������܂��B
�񓧉ߕ������h���b�O����ƈړ��ł��A�E���̃n���h�����h���b�O����ƃT�C�Y�̕ύX���ł��܂��B

ACT �̃v���O�C���^�u�ɂ���uOverlayPlugin.dll�v�^�u�ŁA�\���̐؂�ւ���}�E�X�N���b�N�̓��߁A�\������t�@�C���̐ݒ�Ȃǂ��ł��܂��B

## �g���u���V���[�e�B���O

�I�[�o�[���C�E�B���h�E�Ȃǂ��\������Ȃ��ꍇ�́A�uPlugins�v�^�u�ɂ���uOverlayPlugin.dll�v�^�u���̉����ɂ��郍�O�̃��b�Z�[�W���悭�m�F���Ă��������B

### `Error: AssemblyResolve: => System.NotSupportedException: �l�b�g���[�N��̏ꏊ����i�ȉ����j` �Ƃ������O���\�������

�C���^�[�l�b�g����_�E�����[�h����ZIP�t�@�C�����E�B���h�E�Y�W����ZIP�W�J�@�\���g�p����ƁA�M���ł��Ȃ��t�@�C���Ƃ��ăt�@�C���Ƀt���O���t�^����邱�Ƃ�����܂��B

���̃t���O�����Ă���ꍇ�A���̐M���ł��Ȃ����s�t�@�C����DLL��ǂݍ��ނ��Ƃ��ł����A��L�̃G���[���������邱�Ƃ�����܂��B

�G�N�X�v���[���[�Ńt�@�C�����E�N���b�N���ăv���p�e�B��I�����A�����ɂ���u�u���b�N�̉����v�{�^�����������Ƃł��̃t���O���������邱�Ƃ��ł��܂��̂ŁA���ׂĂ� DLL �t�@�C���̃t���O���������Ă��������B

�܂��A�l�b�g���[�N�h���C�u���g�p���Ă���ꍇ�ɂ��A���̃G���[���o��\��������܂��B���[�J���h���C�u�Ƀt�@�C�����ڂ��Ă���g�p���Ă��������B

### `Error: AssemblyResolve: => System.IO.FileNotFoundException: �w�肳�ꂽ�t�@�C�����i�ȉ����j` �Ƃ������O���\�������

�v���O�C��������DLL�Ɠ����ꏊ�ɁA�K�v��DLL���z�u����Ă��܂���B

�g�p���@�ɂ������Ă���悤�ɁAOverlayPlugin.dll �P�̂�ʂ̏ꏊ�ɃR�s�[���Ďg�p���邱�Ƃ͂ł��܂���B�ړ�������ꍇ�͑��̃t�@�C���ƈꏏ�Ɉړ������Ă��������B

### ���̊Ԃɂ��őO�ʂ���Ȃ��Ȃ��Ă���

�����炭�E�B���h�E�Y�̎d�l�ł��B��x��\���ɂ��čēx�\��������ƒ���܂��B

## �J�X�^�}�C�Y

�v���O�C�����z�u����Ă���t�H���_�ɂ��� resources �t�H���_�̒��́Adefault.html ��ҏW���邱�ƂŃJ�X�^�}�C�Y���ł��܂��B 

JavaScript �� HTML �Ɋւ����b�I�Ȓm��������ΕҏW�ł���Ǝv���܂��B

## ���C�Z���X

MIT ���C�Z���X�ł��B�ڍׂ� LICENSE.txt ���Q�Ƃ��Ă��������B
