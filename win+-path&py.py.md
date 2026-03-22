import os
import winreg
import ctypes
import argparse
import sys

def notify_system():
    """广播系统消息，让环境变量更改在不重启的情况下生效"""
    SendMessageTimeout = ctypes.windll.user32.SendMessageTimeoutW
    # HWND_BROADCAST: 0xFFFF, WM_SETTINGCHANGE: 0x001A
    SendMessageTimeout(0xFFFF, 0x001A, 0, "Environment", 0x0002, 1000, ctypes.byref(ctypes.c_long()))

def get_target_dir():
    """获取脚本文件实际存放的绝对路径（非执行路径）"""
    return os.path.normpath(os.path.dirname(os.path.abspath(sys.argv[0])))

def manage_env(remove=False):
    target_dir = get_target_dir()
    print("=" * 50)
    print(f"执行模式: {'【 卸载 / 移除 】' if remove else '【 安装 / 配置 】'}")
    print(f"操作路径: {target_dir}")
    print("=" * 50)

    try:
        # 打开 HKEY_CURRENT_USER\Environment
        reg_key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment", 0, winreg.KEY_ALL_ACCESS)
        
        # --- 1. 处理 PATH ---
        try:
            path_value, reg_type = winreg.QueryValueEx(reg_key, "Path")
        except FileNotFoundError:
            path_value, reg_type = "", winreg.REG_EXPAND_SZ

        path_list = [p.strip() for p in path_value.split(';') if p.strip()]
        norm_target = target_dir.lower()

        if remove:
            # 过滤掉所有指向当前目录的条目（防重复残留）
            new_path_list = [p for p in path_list if os.path.normpath(p).lower() != norm_target]
            if len(new_path_list) < len(path_list):
                winreg.SetValueEx(reg_key, "Path", 0, reg_type, ";".join(new_path_list))
                print("✅ 已成功从系统 Path 中移除该路径。")
            else:
                print("ℹ️ Path 中未发现该路径，无需清理。")
        else:
            # 检查是否已存在
            if norm_target not in [os.path.normpath(p).lower() for p in path_list]:
                new_path_str = (path_value.rstrip(';') + ';' + target_dir).lstrip(';')
                # 安全检查：Path 长度预警
                if len(new_path_str) > 2000:
                    print("⚠️ 警告：Path 变量长度接近 2048 限制，请手动清理不用的路径！")
                winreg.SetValueEx(reg_key, "Path", 0, reg_type, new_path_str)
                print("✅ 已成功将当前路径加入 Path。")
            else:
                print("ℹ️ 该路径已在 Path 中，无需重复添加。")

        # --- 2. 处理 PATHEXT ---
        try:
            ext_value, ext_type = winreg.QueryValueEx(reg_key, "PATHEXT")
        except FileNotFoundError:
            ext_value, ext_type = ".COM;.EXE;.BAT;.CMD", winreg.REG_SZ

        ext_list = [e.strip().upper() for e in ext_value.split(';') if e.strip()]
        
        if remove:
            if ".PY" in ext_list:
                ext_list.remove(".PY")
                winreg.SetValueEx(reg_key, "PATHEXT", 0, ext_type, ";".join(ext_list))
                print("✅ 已移除 .PY 后缀执行支持。")
        else:
            if ".PY" not in ext_list:
                ext_list.append(".PY")
                winreg.SetValueEx(reg_key, "PATHEXT", 0, ext_type, ";".join(ext_list))
                print("✅ 已开启 .PY 后缀直接运行支持。")

        winreg.CloseKey(reg_key)
        notify_system()
        print("\n🎉 全部操作已完成！请重启您的命令行窗口（CMD/PowerShell）。")

    except Exception as e:
        print(f"❌ 发生致命错误: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Windows 脚本环境一键配置工具")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--install", action="store_true", help="安装：添加路径及后缀支持")
    group.add_argument("--uninstall", action="store_true", help="卸载：移除路径及后缀支持")
    
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(0)
        
    args = parser.parse_args()
    manage_env(remove=args.uninstall)