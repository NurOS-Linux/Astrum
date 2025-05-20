#pragma once

#include <QApplication>
#include <QMainWindow>
#include <QWidget>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QLabel>
#include <QLineEdit>
#include <QSplitter>
#include <QToolBar>
#include <QStatusBar>
#include <QScrollArea>
#include <QListWidget>
#include <QListWidgetItem>
#include <QAbstractItemView>
#include <QAction>
#include <QIcon>
#include <QDir>
#include <QSize>
#include <QMenuBar>
#include <QFileInfo>
#include <QProcess>
#include <QMessageBox>
#include <QInputDialog>
#include <QEvent>
#include <QComboBox>
#include <QMenu>
#include <QFileDialog>
#include <QMimeDatabase>
#include <QClipboard>
#include <QDesktopServices>
#include <QUrl>
#include <QContextMenuEvent>

// Цвета в стиле нью-минимализм темный - более глубокий темный
const QString BG_DARK = "#0A0A0A";           // Ещё более темный фон (почти черный)
const QString SURFACE_DARK = "#141414";      // Темная поверхность элементов
const QString FILE_VIEW_BG = "#0D0D0D";      // Темный фон для области файлов (между BG_DARK и SURFACE_DARK)
const QString ACCENT_COLOR = "#BB86FC";      // Лавандовый акцент
const QString SECONDARY_ACCENT = "#03DAC6";  // Бирюзовый акцент
const QString TEXT_PRIMARY = "#FFFFFF";      // Белый текст для важной информации
const QString TEXT_SECONDARY = "#B3FFFFFF";  // Полупрозрачный белый для вторичного текста
const QString DIVIDER_COLOR = "#222222";     // Цвет разделителей

// Объявление класса FileIconView
class FileIconView : public QScrollArea {
    Q_OBJECT

public:
    FileIconView(QWidget* parent = nullptr);
    void clear();
    void add_item(const QString& name, const QString& path, bool is_dir = false);
    
    // Для доступа к layout из класса AstrumFileManager
    QVBoxLayout* layout;
    
    // Метод для получения выбранного элемента
    QWidget* getSelectedItem() const { return selectedItem; }
    QString getSelectedPath() const;

signals:
    void itemClicked(const QString& path);
    void itemRightClicked(const QString& path, const QPoint& pos);

protected:
    bool eventFilter(QObject* obj, QEvent* event) override;
    void contextMenuEvent(QContextMenuEvent* event) override;

private:
    QWidget* widget;
    int icon_size;
    
    // Выбранный элемент
    QWidget* selectedItem;
};

// Объявление класса AstrumFileManager
class AstrumFileManager : public QMainWindow {
    Q_OBJECT

public:
    AstrumFileManager(QWidget* parent = nullptr);
    ~AstrumFileManager();

private slots:
    // Навигация
    void goBack();
    void goForward();
    void goUp();
    void refreshView();
    
    // Файловые операции
    void createNewFolder();
    void deleteSelected();
    void renameSelected();
    void copySelected();
    void cutSelected();
    void paste();
    void showProperties();
    
    // Закладки
    void bookmarkClicked(QListWidgetItem* item);
    void fileItemClicked(const QString& path);
    void fileItemRightClicked(const QString& path, const QPoint& pos);
    
    // Фильтрация
    void applyFilter();
    void clearFilter();
    void filterTextChanged(const QString& text);
    
    // Прочее
    void openWith();
    void openContainingFolder();
    void openInTerminal();
    
    // О программе
    void showAboutDialog();

private:
    QAction* create_action(const QIcon& icon, const QString& tip);
    void add_bookmark(const QIcon& icon, const QString& name, const QString& path);
    void applyStyles();
    void connectSignals();
    void createMenu();
    void updatePath(const QString& path);
    void updateItemCount(const QString& path, bool filtered = false);
    void displayDirectoryContents(const QString& path);
    void openFile(const QString& path);
    void updateUserInfo();
    
    // Создание контекстного меню
    QMenu* createFileContextMenu(const QString& path);
    QMenu* createDirectoryContextMenu(const QString& path);
    QMenu* createEmptyAreaContextMenu();
    
    // Вспомогательная функция для рекурсивного копирования директории
    bool copyDirectory(const QString& sourceDir, const QString& destDir);
    
    // Буфер обмена для операций копирования/вставки
    QString clipboard_path;
    bool is_cut;

    // Навигация
    QToolBar* toolbar;
    QAction* back_btn;
    QAction* forward_btn;
    QAction* up_btn;
    QAction* refresh_btn;
    QAction* new_folder_btn;
    QAction* delete_btn;
    QLineEdit* path_edit;
    
    // Фильтрация
    QLineEdit* filter_edit;
    QComboBox* filter_type;
    QPushButton* filter_btn;
    QPushButton* clear_btn;
    
    // Основной интерфейс
    QSplitter* splitter;
    QListWidget* bookmarks;
    FileIconView* file_icon_view;
    QStatusBar* status_bar;
    QLabel* items_label;
    QLabel* user_label;
};