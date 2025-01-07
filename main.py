#!/usr/bin/env python3

import sys
import os
import shutil
import subprocess
from datetime import datetime
from PyQt5.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLineEdit, QListWidget, QLabel, QListView, QMenu, QMessageBox, QDialog, QPushButton,
    QGridLayout, QInputDialog, QListWidgetItem, QFileSystemModel
)
from PyQt5.QtCore import QDir, Qt, QSize

class AstrumFM(QMainWindow):
    def __init__(self):
        super().__init__()
        self.init_ui()
        self.setup_styles()
        
    def init_ui(self):
        self.setWindowTitle('Astrum')
        self.setGeometry(100, 100, 1200, 700)

        main_widget = QWidget()
        self.setCentralWidget(main_widget)
        layout = QHBoxLayout(main_widget)
        
        # Left panel
        left_widget = QWidget()
        left_layout = QVBoxLayout(left_widget)
        left_widget.setFixedWidth(200)
        
        # Quick access
        self.quick_access = QListWidget()
        self.setup_quick_access()
        left_layout.addWidget(QLabel("Quick Access"))
        left_layout.addWidget(self.quick_access)
        
        # Devices 
        self.devices = QListWidget()
        self.setup_devices()
        left_layout.addWidget(QLabel("Devices"))
        left_layout.addWidget(self.devices)
        
        # Bookmarks
        self.bookmarks = QListWidget()
        self.setup_bookmarks()
        left_layout.addWidget(QLabel("Bookmarks"))
        left_layout.addWidget(self.bookmarks)
        
        layout.addWidget(left_widget)
        
        # Right panel
        right_widget = QWidget()
        right_layout = QVBoxLayout(right_widget)
        
        # Path bar
        self.path_input = QLineEdit()
        self.path_input.setPlaceholderText("Enter path...")
        self.path_input.returnPressed.connect(self.navigate_to_path)
        right_layout.addWidget(self.path_input)
        
        # Files
        self.files = QListView()
        self.fs_model = QFileSystemModel()
        self.fs_model.setRootPath(QDir.homePath())
        self.files.setModel(self.fs_model)
        self.files.setRootIndex(self.fs_model.index(QDir.homePath()))
        self.files.setViewMode(QListView.IconMode)
        self.files.setGridSize(QSize(100, 100))
        self.files.setContextMenuPolicy(Qt.CustomContextMenu)
        self.files.customContextMenuRequested.connect(self.show_context_menu)
        right_layout.addWidget(self.files)
        
        layout.addWidget(right_widget)

        # Signals
        self.files.doubleClicked.connect(self.open_file)
        self.quick_access.itemClicked.connect(self.on_quick_access_clicked)
        self.devices.itemClicked.connect(self.on_device_clicked)
        self.bookmarks.itemClicked.connect(self.on_bookmark_clicked)

    def setup_quick_access(self):
        locations = {
            "🏠 Home": QDir.homePath(),
            "💻 Root": "/",
            "🖥️ Desktop": os.path.join(QDir.homePath(), "Desktop"),
            "📄 Documents": os.path.join(QDir.homePath(), "Documents"),
            "⬇️ Downloads": os.path.join(QDir.homePath(), "Downloads"),
            "🖼️ Pictures": os.path.join(QDir.homePath(), "Pictures")
        }
        
        for name, path in locations.items():
            if os.path.exists(path):
                item = QListWidgetItem(name)
                item.setData(Qt.UserRole, path)
                self.quick_access.addItem(item)

    def setup_devices(self):
        try:
            with open('/proc/mounts', 'r') as f:
                for line in f:
                    if line.startswith('/dev/'):
                        dev, mount, *_ = line.split()
                        name = f"💾 {os.path.basename(mount)}"
                        item = QListWidgetItem(name)
                        item.setData(Qt.UserRole, mount)
                        self.devices.addItem(item)
        except: pass

    def setup_bookmarks(self):
        self.bookmarks_file = os.path.expanduser('~/.config/astrum/bookmarks')
        os.makedirs(os.path.dirname(self.bookmarks_file), exist_ok=True)
        
        try:
            if os.path.exists(self.bookmarks_file):
                with open(self.bookmarks_file, 'r') as f:
                    for line in f:
                        name, path = line.strip().split('|')
                        if os.path.exists(path):
                            item = QListWidgetItem(f"🔖 {name}")
                            item.setData(Qt.UserRole, path)
                            self.bookmarks.addItem(item)
        except: pass

    def show_context_menu(self, pos):
        menu = QMenu()
        current = self.fs_model.filePath(self.files.currentIndex())
        
        if os.path.exists(current):
            menu.addAction("📁 New Folder", self.create_folder)
            menu.addAction("🔖 Add Bookmark", lambda: self.add_bookmark(current))
            menu.addAction("🗑️ Delete", self.delete_selected)
            menu.addAction("ℹ️ Properties", self.show_properties)
            
            if not os.access(current, os.W_OK):
                menu.addAction("🔒 Open as Root", lambda: self.open_as_root(current))
        
        menu.exec(self.sender().mapToGlobal(pos))

    def navigate_to_path(self):
        path = self.path_input.text()
        if os.path.exists(path):
            self.navigate_to(path)

    def open_file(self, index):
        path = self.fs_model.filePath(index)
        if os.path.isdir(path):
            self.navigate_to(path)
        else:
            try:
                subprocess.Popen(['xdg-open', path])
            except Exception as e:
                QMessageBox.critical(self, "Error", str(e))

    def create_folder(self):
        name, ok = QInputDialog.getText(self, "New Folder", "Name:")
        if ok and name:
            path = os.path.join(self.fs_model.filePath(self.files.rootIndex()), name)
            try:
                if not os.access(path, os.W_OK):
                    self.run_as_root(['mkdir', path])
                else:
                    os.makedirs(path)
            except Exception as e:
                QMessageBox.critical(self, "Error", str(e))

    def add_bookmark(self, path):
        name, ok = QInputDialog.getText(self, "Add Bookmark", "Name:")
        if ok and name:
            item = QListWidgetItem(f"🔖 {name}")
            item.setData(Qt.UserRole, path)
            self.bookmarks.addItem(item)
            
            with open(self.bookmarks_file, 'a') as f:
                f.write(f"{name}|{path}\n")

    def on_quick_access_clicked(self, item):
        self.navigate_to(item.data(Qt.UserRole))

    def on_device_clicked(self, item):
        self.navigate_to(item.data(Qt.UserRole))

    def on_bookmark_clicked(self, item):
        self.navigate_to(item.data(Qt.UserRole))

    def navigate_to(self, path):
        if os.access(path, os.R_OK):
            self.files.setRootIndex(self.fs_model.index(path))
            self.path_input.setText(path)
        else:
            reply = QMessageBox.question(
                self, 
                "Permission Denied",
                f"Access to {path} is denied.\nWould you like to open it as root?",
                QMessageBox.Yes | QMessageBox.No
            )
            if reply == QMessageBox.Yes:
                self.open_as_root(path)

    def open_as_root(self, path):
        try:
            self.run_as_root(['xdg-open', path])
        except Exception as e:
            QMessageBox.critical(self, "Error", str(e))

    def delete_selected(self):
        selected = self.files.selectedIndexes()
        if not selected:
            return
            
        files = [self.fs_model.filePath(index) for index in selected]
        msg = f"Delete {len(files)} item(s)?\n\n" + "\n".join(files)
        
        reply = QMessageBox.question(
            self, 
            "Confirm Delete",
            msg,
            QMessageBox.Yes | QMessageBox.No
        )
        
        if reply == QMessageBox.Yes:
            for file_path in files:
                try:
                    if not os.access(file_path, os.W_OK):
                        self.run_as_root(['rm', '-rf', file_path])
                    else:
                        if os.path.isdir(file_path):
                            shutil.rmtree(file_path)
                        else:
                            os.remove(file_path)
                except Exception as e:
                    QMessageBox.critical(self, "Error", f"Could not delete {file_path}\n{str(e)}")

    def show_properties(self):
        selected = self.files.selectedIndexes()
        if not selected:
            return
            
        file_path = self.fs_model.filePath(selected[0])
        stat = os.stat(file_path)
        
        dialog = QDialog(self)
        dialog.setWindowTitle("Properties")
        dialog.setFixedSize(400, 300)
        
        layout = QVBoxLayout(dialog)
        grid = QGridLayout()
        row = 0
        
        grid.addWidget(QLabel("Name:"), row, 0)
        grid.addWidget(QLabel(os.path.basename(file_path)), row, 1)
        row += 1
        
        grid.addWidget(QLabel("Path:"), row, 0)
        grid.addWidget(QLabel(os.path.dirname(file_path)), row, 1)
        row += 1
        
        grid.addWidget(QLabel("Type:"), row, 0)
        ftype = "Directory" if os.path.isdir(file_path) else "File"
        grid.addWidget(QLabel(ftype), row, 1)
        row += 1
        
        if os.path.isfile(file_path):
            size = stat.st_size
            size_str = f"{size} B" if size < 1024 else f"{size/1024:.1f} KB" if size < 1024**2 else f"{size/1024**2:.1f} MB" if size < 1024**3 else f"{size/1024**3:.1f} GB"
            grid.addWidget(QLabel("Size:"), row, 0)
            grid.addWidget(QLabel(size_str), row, 1)
            row += 1
        
        perms = stat.st_mode
        perm_str = "".join(["r" if perms & 0o400 else "-", "w" if perms & 0o200 else "-", "x" if perms & 0o100 else "-", " ", "r" if perms & 0o040 else "-", "w" if perms & 0o020 else "-", "x" if perms & 0o010 else "-", " ", "r" if perms & 0o004 else "-", "w" if perms & 0o002 else "-", "x" if perms & 0o001 else "-"])
        grid.addWidget(QLabel("Permissions:"), row, 0)
        grid.addWidget(QLabel(perm_str), row, 1)
        row += 1
        
        try:
            import pwd
            owner = pwd.getpwuid(stat.st_uid).pw_name
        except:
            owner = str(stat.st_uid)
        
        grid.addWidget(QLabel("Owner:"), row, 0)
        grid.addWidget(QLabel(owner), row, 1)
        row += 1
        
        grid.addWidget(QLabel("Created:"), row, 0)
        grid.addWidget(QLabel(datetime.fromtimestamp(stat.st_ctime).strftime("%Y-%m-%d %H:%M:%S")), row, 1)
        row += 1
        
        grid.addWidget(QLabel("Modified:"), row, 0)
        grid.addWidget(QLabel(datetime.fromtimestamp(stat.st_mtime).strftime("%Y-%m-%d %H:%M:%S")), row, 1)
        row += 1
        
        grid.addWidget(QLabel("Accessed:"), row, 0)
        grid.addWidget(QLabel(datetime.fromtimestamp(stat.st_atime).strftime("%Y-%m-%d %H:%M:%S")), row, 1)
        
        layout.addLayout(grid)
        
        btn = QPushButton("Close")
        btn.clicked.connect(dialog.close)
        layout.addWidget(btn)
        
        dialog.setStyleSheet("""
            QDialog { background-color: #ffffff; color: #000000; border-radius: 12px; }
            QLabel { color: #000000; padding: 5px; }
            QPushButton { background-color: #f0f0f0; color: #000000; border: 1px solid #d0d0d0; border-radius: 6px; padding: 5px 16px; }
            QPushButton:hover { background-color: #e0e0e0; border-color: #c0c0c0; }
        """)
        
        dialog.exec()

    def run_as_root(self, command):
        try:
            subprocess.run(['sudo'] + command, check=True)
        except subprocess.CalledProcessError as e:
            QMessageBox.critical(self, "Error", f"Command failed: {e}")

    def setup_styles(self):
        radius = 12
        self.setStyleSheet(f"""
        QMainWindow {{
            background-color: #ffffff;
            color: #000000;
            border-radius: {radius}px;
        }}
        QLineEdit {{
            background-color: #f0f0f0;
            border: 1px solid #d0d0d0;
            border-radius: {radius}px;
            color: #000000;
            padding: 8px;
            font-size: 14px;
            margin: 5px;
        }}
        QListWidget {{
            background-color: #f0f0f0;
            border: 1px solid #d0d0d0;
            border-radius: {radius}px;
            color: #000000;
            font-size: 14px;
            padding: 5px;
        }}
        QListWidget::item {{
            border-radius: {radius-4}px;
            padding: 8px;
            margin: 2px;
        }}
        QListWidget::item:selected {{
            background-color: #007aff;
            color: white;
        }}
        QTreeView, QListView {{
            background-color: #ffffff;
            border: 1px solid #d0d0d0;
            border-radius: {radius}px;
            color: #000000;
            padding: 5px;
        }}
        QTreeView::item, QListView::item {{
            border-radius: {radius-4}px;
            margin: 2px;
        }}
        QTreeView::item:selected, QListView::item:selected {{
            background-color: #007aff;
            color: white;
        }}
        QMenu {{
            background-color: #ffffff;
            border: 1px solid #d0d0d0;
            border-radius: {radius}px;
            color: #000000;
            padding: 5px;
        }}
        QMenu::item {{
            padding: 8px 20px;
            border-radius: {radius-4}px;
        }}
        QMenu::item:selected {{
            background-color: #007aff;
        }}
        QScrollBar:vertical {{
            background-color: #ffffff;
            width: 12px;
            border-radius: {radius-4}px;
        }}
        QScrollBar::handle:vertical {{
            background-color: #d0d0d0;
            border-radius: {radius-4}px;
            min-height: 20px;
        }}
        QScrollBar::handle:vertical:hover {{
            background-color: #007aff;
        }}
        """)

def main():
    app = QApplication(sys.argv)
    app.setApplicationName('kz.delta.astrum')
    window = AstrumFM()
    window.show()
    sys.exit(app.exec_())

if __name__ == '__main__':
    main()