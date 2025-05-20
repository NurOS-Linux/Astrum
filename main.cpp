#include "astrum.hpp"

// Реализация класса FileIconView
FileIconView::FileIconView(QWidget* parent) : QScrollArea(parent) {
    setWidgetResizable(true);
    widget = new QWidget();
    layout = new QVBoxLayout(widget);
    layout->setAlignment(Qt::AlignTop);
    layout->setSpacing(12); // Увеличенное расстояние между элементами
    layout->setContentsMargins(16, 16, 16, 16);
    setWidget(widget);
    
    // Более темный фон для области файлов
    widget->setStyleSheet(QString("background-color: %1;").arg(FILE_VIEW_BG));
    
    // Стиль для нью-минимализма с более темным фоном
    setStyleSheet(QString(
        "QScrollArea {"
        "   background-color: %1;"
        "   border: none;"
        "}"
        "QScrollBar:vertical {"
        "   background: %1;"
        "   width: 8px;"
        "   margin: 0px;"
        "}"
        "QScrollBar::handle:vertical {"
        "   background: %2;"
        "   min-height: 30px;"
        "   border-radius: 4px;"
        "}"
        "QScrollBar::add-line:vertical, QScrollBar::sub-line:vertical {"
        "   height: 0px;"
        "}"
    ).arg(FILE_VIEW_BG).arg(TEXT_SECONDARY));
    
    icon_size = 48; // Размер иконки для минималистичного стиля
    selectedItem = nullptr;
}

QString FileIconView::getSelectedPath() const {
    if (selectedItem) {
        return selectedItem->property("path").toString();
    }
    return QString();
}

void FileIconView::clear() {
    selectedItem = nullptr;
    QLayoutItem* item;
    while ((item = layout->takeAt(0)) != nullptr) {
        if (item->widget()) {
            delete item->widget();
        }
        delete item;
    }
}

void FileIconView::add_item(const QString& name, const QString& path, bool is_dir) {
    QWidget* item_widget = new QWidget();
    QVBoxLayout* item_layout = new QVBoxLayout(item_widget);
    item_layout->setAlignment(Qt::AlignHCenter);
    item_layout->setContentsMargins(8, 8, 8, 8);
    item_widget->setFixedSize(icon_size + 24, icon_size + 44);

    QIcon icon;
    if (is_dir) {
        icon = QIcon::fromTheme("folder");
    } else {
        icon = QIcon::fromTheme("text-x-generic");
    }

    QLabel* icon_label = new QLabel();
    icon_label->setPixmap(icon.pixmap(icon_size, icon_size));
    icon_label->setAlignment(Qt::AlignHCenter);

    QLabel* text_label = new QLabel(name);
    text_label->setAlignment(Qt::AlignHCenter);
    text_label->setWordWrap(true);
    // Повышенная яркость текста для лучшей видимости на темном фоне
    text_label->setStyleSheet(QString("color: %1; font-size: 10pt;").arg(TEXT_PRIMARY));

    item_layout->addWidget(icon_label);
    item_layout->addWidget(text_label);

    // Более заметный эффект при наведении на темном фоне
    QString style = QString(
        "QWidget {"
        "   background-color: transparent;"
        "   border-radius: 8px;"
        "}"
        "QWidget:hover {"
        "   background-color: rgba(255, 255, 255, 0.12);" // Более заметное подсвечивание на темном фоне
        "}"
    );
    item_widget->setStyleSheet(style);

    item_widget->setProperty("path", path);
    item_widget->installEventFilter(this);

    layout->addWidget(item_widget);
}

bool FileIconView::eventFilter(QObject* obj, QEvent* event) {
    QWidget* widget = qobject_cast<QWidget*>(obj);
    
    if (!widget)
        return QScrollArea::eventFilter(obj, event);
    
    if (event->type() == QEvent::MouseButtonPress) {
        QMouseEvent* mouseEvent = static_cast<QMouseEvent*>(event);
        
        if (mouseEvent->button() == Qt::LeftButton) {
            // Обработка левого клика
            selectedItem = widget;
            widget->setFocus();
            QString path = widget->property("path").toString();
            emit itemClicked(path);
            return true;
        }
        else if (mouseEvent->button() == Qt::RightButton) {
            // Обработка правого клика
            selectedItem = widget;
            widget->setFocus();
            QString path = widget->property("path").toString();
            emit itemRightClicked(path, mouseEvent->globalPosition().toPoint());
            return true;
        }
    }
    
    return QScrollArea::eventFilter(obj, event);
}

void FileIconView::contextMenuEvent(QContextMenuEvent* event) {
    // Сигнал с пустым путем для создания контекстного меню для пустой области
    emit itemRightClicked("", event->globalPos());
    event->accept();
}

// Реализация класса AstrumFileManager
AstrumFileManager::AstrumFileManager(QWidget* parent) : QMainWindow(parent) {
    setWindowTitle("Astrum");
    setMinimumSize(1000, 700);

    // Инициализация буфера обмена
    clipboard_path = "";
    is_cut = false;

    // 1. Центральный виджет и основной макет
    QWidget* central_widget = new QWidget();
    setCentralWidget(central_widget);
    QVBoxLayout* main_layout = new QVBoxLayout(central_widget);
    main_layout->setContentsMargins(0, 0, 0, 0);
    main_layout->setSpacing(0);

    // 2. Панель инструментов - более плоский и минималистичный стиль
    toolbar = new QToolBar();
    addToolBar(toolbar);
    toolbar->setIconSize(QSize(20, 20));
    toolbar->setMovable(false); // Фиксированная панель инструментов
    toolbar->setStyleSheet(QString(
        "QToolBar {"
        "   background-color: %1;"
        "   border: none;"
        "   padding: 8px;"
        "   spacing: 4px;"
        "}"
        "QToolButton {"
        "   background-color: transparent;"
        "   border: none;"
        "   padding: 8px;"
        "   border-radius: 4px;"
        "}"
        "QToolButton:hover {"
        "   background-color: rgba(255, 255, 255, 0.1);"
        "}"
        "QToolButton:pressed {"
        "   background-color: rgba(255, 255, 255, 0.15);"
        "}"
    ).arg(BG_DARK));

    // Кнопки панели инструментов
    back_btn = create_action(QIcon::fromTheme("go-previous"), "Back");
    forward_btn = create_action(QIcon::fromTheme("go-next"), "Forward");
    up_btn = create_action(QIcon::fromTheme("go-up"), "Up");
    refresh_btn = create_action(QIcon::fromTheme("view-refresh"), "Refresh");
    new_folder_btn = create_action(QIcon::fromTheme("folder-new"), "New Folder");
    delete_btn = create_action(QIcon::fromTheme("edit-delete"), "Delete");

    toolbar->addAction(back_btn);
    toolbar->addAction(forward_btn);
    toolbar->addAction(up_btn);
    toolbar->addAction(refresh_btn);
    toolbar->addAction(new_folder_btn);
    toolbar->addAction(delete_btn);
    toolbar->addSeparator();

    // 3. Строка пути - минималистичный дизайн
    path_edit = new QLineEdit();
    path_edit->setObjectName("pathEdit");
    path_edit->setReadOnly(true);
    path_edit->setStyleSheet(QString(
        "QLineEdit {"
        "   background-color: %1;"
        "   color: %2;"
        "   border: none;"
        "   border-radius: 4px;"
        "   padding: 8px;"
        "   font-size: 10pt;"
        "}"
    ).arg(SURFACE_DARK).arg(TEXT_PRIMARY));
    toolbar->addWidget(path_edit);

    // Создаем виджеты для фильтрации
    QWidget* filter_widget = new QWidget();
    QHBoxLayout* filter_layout = new QHBoxLayout(filter_widget);
    filter_layout->setContentsMargins(5, 0, 5, 0);
    filter_layout->setSpacing(5);

    // Метка
    QLabel* filter_label = new QLabel("Filter:");
    filter_label->setStyleSheet(QString("color: %1;").arg(TEXT_PRIMARY));
    filter_layout->addWidget(filter_label);

    // Поле фильтрации
    filter_edit = new QLineEdit();
    filter_edit->setPlaceholderText("Enter filter term...");
    filter_edit->setStyleSheet(QString(
        "QLineEdit {"
        "   background-color: %1;"
        "   color: %2;"
        "   border: none;"
        "   border-radius: 4px;"
        "   padding: 5px;"
        "   font-size: 9pt;"
        "}"
    ).arg(SURFACE_DARK).arg(TEXT_PRIMARY));
    filter_layout->addWidget(filter_edit);

    // Комбо-бокс для типа фильтрации
    filter_type = new QComboBox();
    filter_type->addItem("Name", "name");
    filter_type->addItem("Type", "type");
    filter_type->addItem("Size", "size");
    filter_type->setStyleSheet(QString(
        "QComboBox {"
        "   background-color: %1;"
        "   color: %2;"
        "   border: none;"
        "   border-radius: 4px;"
        "   padding: 4px;"
        "   font-size: 9pt;"
        "}"
        "QComboBox::drop-down {"
        "   border: none;"
        "   width: 20px;"
        "}"
        "QComboBox::down-arrow {"
        "   image: url(down-arrow.png);"
        "   width: 12px;"
        "   height: 12px;"
        "}"
        "QComboBox QAbstractItemView {"
        "   background-color: %1;"
        "   color: %2;"
        "   selection-background-color: %3;"
        "   selection-color: %1;"
        "   border: 1px solid %4;"
        "   border-radius: 2px;"
        "}"
    ).arg(SURFACE_DARK).arg(TEXT_PRIMARY).arg(ACCENT_COLOR).arg(DIVIDER_COLOR));
    filter_layout->addWidget(filter_type);

    // Кнопки фильтрации
    filter_btn = new QPushButton("Apply");
    filter_btn->setStyleSheet(QString(
        "QPushButton {"
        "   background-color: %1;"
        "   color: %2;"
        "   border: none;"
        "   border-radius: 4px;"
        "   padding: 5px 10px;"
        "   font-size: 9pt;"
        "}"
        "QPushButton:hover {"
        "   background-color: %3;"
        "}"
    ).arg(ACCENT_COLOR).arg(BG_DARK).arg(SECONDARY_ACCENT));
    filter_layout->addWidget(filter_btn);

    clear_btn = new QPushButton("Clear");
    clear_btn->setStyleSheet(QString(
        "QPushButton {"
        "   background-color: %1;"
        "   color: %2;"
        "   border: none;"
        "   border-radius: 4px;"
        "   padding: 5px 10px;"
        "   font-size: 9pt;"
        "}"
        "QPushButton:hover {"
        "   background-color: rgba(255, 255, 255, 0.15);"
        "}"
    ).arg(SURFACE_DARK).arg(TEXT_PRIMARY));
    filter_layout->addWidget(clear_btn);

    toolbar->addWidget(filter_widget);

    // 4. Разделитель (Bookmarks + FileIconView)
    splitter = new QSplitter(Qt::Horizontal);
    splitter->setHandleWidth(1); // Тонкая линия разделителя
    splitter->setStyleSheet(QString(
        "QSplitter {"
        "   background-color: %1;"
        "}"
        "QSplitter::handle {"
        "   background-color: %2;"
        "}"
    ).arg(BG_DARK).arg(DIVIDER_COLOR));

    // Левая часть: Bookmarks
    bookmarks = new QListWidget();
    bookmarks->setObjectName("bookmarks");
    bookmarks->setViewMode(QListWidget::ListMode);
    bookmarks->setSelectionMode(QAbstractItemView::SingleSelection);
    bookmarks->setSpacing(2);
    bookmarks->setStyleSheet(QString(
        "QListWidget {"
        "   background-color: %1;"
        "   color: %2;"
        "   border: none;"
        "   padding: 8px;"
        "}"
        "QListWidget::item {"
        "   padding: 8px;"
        "   border-radius: 4px;"
        "}"
        "QListWidget::item:selected {"
        "   background-color: %3;"
        "   color: %1;"
        "}"
        "QListWidget::item:hover:!selected {"
        "   background-color: rgba(255, 255, 255, 0.1);"
        "}"
    ).arg(SURFACE_DARK).arg(TEXT_PRIMARY).arg(ACCENT_COLOR));

    // Add bookmarks - обновленный список с добавлением домашней и корневой директорий
    add_bookmark(QIcon::fromTheme("user-home"), "Home", QDir::homePath());  // Домашняя директория (~)
    add_bookmark(QIcon::fromTheme("drive-harddisk"), "Root", "/");  // Корневая директория (/)
    add_bookmark(QIcon::fromTheme("folder-download"), "Downloads", QDir::homePath() + "/Downloads");
    add_bookmark(QIcon::fromTheme("folder-documents"), "Documents", QDir::homePath() + "/Documents");
    add_bookmark(QIcon::fromTheme("folder-pictures"), "Pictures", QDir::homePath() + "/Pictures");
    add_bookmark(QIcon::fromTheme("folder-music"), "Music", QDir::homePath() + "/Music");

    // Правая часть: FileIconView
    file_icon_view = new FileIconView();

    splitter->addWidget(bookmarks);
    splitter->addWidget(file_icon_view);
    splitter->setSizes(QList<int>() << 200 << 800);

    // 5. Статусная строка - минималистичная
    status_bar = new QStatusBar();
    setStatusBar(status_bar);
    status_bar->setStyleSheet(QString(
        "QStatusBar {"
        "   background-color: %1;"
        "   color: %2;"
        "   border: none;"
        "}"
    ).arg(BG_DARK).arg(TEXT_SECONDARY));

    items_label = new QLabel("Items: 0");
    items_label->setObjectName("statusLabel");
    items_label->setStyleSheet(QString("color: %1; font-size: 9pt;").arg(TEXT_SECONDARY));

    user_label = new QLabel();
    user_label->setObjectName("statusLabel");
    user_label->setStyleSheet(QString("color: %1; font-size: 9pt;").arg(TEXT_SECONDARY));

    status_bar->addWidget(items_label);
    status_bar->addPermanentWidget(user_label);

    // 6. Добавление виджетов в основной макет
    main_layout->addWidget(toolbar);
    main_layout->addWidget(splitter);

    // 7. Подключение сигналов
    connectSignals();

    // 8. Обновление информации о пользователе
    updateUserInfo();

    // 9. Применение общих стилей
    applyStyles();

    // 10. Создание меню
    createMenu();
    
    // Начальный путь
    displayDirectoryContents(QDir::homePath());
}

AstrumFileManager::~AstrumFileManager() {
    // Cleanup resources if needed
}

void AstrumFileManager::goBack() {
    QString current_path = path_edit->text();
    QDir dir(current_path);
    if (dir.cdUp()) {
        displayDirectoryContents(dir.absolutePath());
    }
}

void AstrumFileManager::goForward() {
    // Заглушка для будущей функциональности истории
}

void AstrumFileManager::goUp() {
    QString current_path = path_edit->text();
    QDir dir(current_path);
    if (dir.cdUp()) {
        displayDirectoryContents(dir.absolutePath());
    }
}

void AstrumFileManager::refreshView() {
    displayDirectoryContents(path_edit->text());
}

void AstrumFileManager::createNewFolder() {
    QString current_path = path_edit->text();
    if (QDir(current_path).exists()) {
        bool ok;
        QString name = QInputDialog::getText(this, "New Folder", 
                                           "Enter folder name:", 
                                           QLineEdit::Normal, 
                                           "", &ok);
        
        if (ok && !name.isEmpty()) {
            QDir dir(current_path);
            if (dir.mkdir(name)) {
                refreshView();
            } else {
                QMessageBox::critical(this, "Error", "Could not create folder.");
            }
        }
    }
}

void AstrumFileManager::deleteSelected() {
    QString current_path = path_edit->text();
    QFileInfo fileInfo(current_path);
    
    if (!fileInfo.exists() || !fileInfo.isWritable()) {
        QMessageBox::critical(this, "Error", "Cannot delete: No write permission in this directory.");
        return;
    }
    
    // Получаем выбранные элементы
    QList<QListWidgetItem*> selected = bookmarks->selectedItems();
    if (!selected.isEmpty()) {
        // Пользователь не может удалять закладки через этот метод
        QMessageBox msgBox;
        msgBox.setWindowTitle("Cannot Delete Bookmark");
        msgBox.setText("Bookmarks cannot be deleted through this method.\nOnly files and folders in the current directory can be deleted.");
        msgBox.setIcon(QMessageBox::Information);
        msgBox.setStyleSheet(QString(
            "QMessageBox {"
            "   background-color: %1;"
            "   color: %2;"
            "}"
            "QLabel {"
            "   color: %2;"
            "}"
            "QPushButton {"
            "   background-color: %3;"
            "   color: %1;"
            "   border: none;"
            "   border-radius: 4px;"
            "   padding: 6px 12px;"
            "   font-weight: bold;"
            "}"
            "QPushButton:hover {"
            "   background-color: %4;"
            "}"
        ).arg(SURFACE_DARK).arg(TEXT_PRIMARY).arg(ACCENT_COLOR).arg(SECONDARY_ACCENT));
        msgBox.exec();
        return;
    }
    
    // Получаем путь к выбранному файлу/папке
    QString path = file_icon_view->getSelectedPath();
    if (path.isEmpty()) {
        // Если ничего не выбрано
        QMessageBox msgBox;
        msgBox.setWindowTitle("No Selection");
        msgBox.setText("Please select a file or folder to delete.");
        msgBox.setIcon(QMessageBox::Information);
        msgBox.setStyleSheet(QString(
            "QMessageBox {"
            "   background-color: %1;"
            "   color: %2;"
            "}"
            "QLabel {"
            "   color: %2;"
            "}"
            "QPushButton {"
            "   background-color: %3;"
            "   color: %1;"
            "   border: none;"
            "   border-radius: 4px;"
            "   padding: 6px 12px;"
            "   font-weight: bold;"
            "}"
            "QPushButton:hover {"
            "   background-color: %4;"
            "}"
        ).arg(SURFACE_DARK).arg(TEXT_PRIMARY).arg(ACCENT_COLOR).arg(SECONDARY_ACCENT));
        msgBox.exec();
        return;
    }
    
    QFileInfo fi(path);
    if (fi.exists()) {
        // Подтверждение удаления
        QMessageBox msgBox;
        msgBox.setWindowTitle("Confirm Delete");
        
        if (fi.isDir()) {
            msgBox.setText(QString("Are you sure you want to delete the folder '%1' and all its contents?").arg(fi.fileName()));
            msgBox.setInformativeText("This action cannot be undone.");
        } else {
            msgBox.setText(QString("Are you sure you want to delete the file '%1'?").arg(fi.fileName()));
            msgBox.setInformativeText("This action cannot be undone.");
        }
        
        msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::No);
        msgBox.setDefaultButton(QMessageBox::No);
        msgBox.setIcon(QMessageBox::Warning);
        
        msgBox.setStyleSheet(QString(
            "QMessageBox {"
            "   background-color: %1;"
            "   color: %2;"
            "}"
            "QLabel {"
            "   color: %2;"
            "}"
            "QPushButton {"
            "   background-color: %3;"
            "   color: %1;"
            "   border: none;"
            "   border-radius: 4px;"
            "   padding: 6px 12px;"
            "   font-weight: bold;"
            "}"
            "QPushButton:hover {"
            "   background-color: %4;"
            "}"
        ).arg(SURFACE_DARK).arg(TEXT_PRIMARY).arg(ACCENT_COLOR).arg(SECONDARY_ACCENT));
        
        int result = msgBox.exec();
        
        if (result == QMessageBox::Yes) {
            bool success = false;
            
            if (fi.isDir()) {
                // Рекурсивное удаление директории
                QDir dir(path);
                success = dir.removeRecursively();
            } else {
                // Удаление файла
                QFile file(path);
                success = file.remove();
            }
            
            if (success) {
                // Обновление вида после успешного удаления
                refreshView();
            } else {
                QMessageBox::critical(this, "Error", QString("Failed to delete %1").arg(fi.fileName()));
            }
        }
    }
}

void AstrumFileManager::renameSelected() {
    QString path = file_icon_view->getSelectedPath();
    if (path.isEmpty()) {
        return;
    }
    
    QFileInfo fileInfo(path);
    if (!fileInfo.exists()) {
        return;
    }
    
    bool ok;
    QString newName = QInputDialog::getText(this, "Rename", 
                                         "Enter new name:", 
                                         QLineEdit::Normal, 
                                         fileInfo.fileName(), &ok);
    
    if (ok && !newName.isEmpty()) {
        QString newPath = fileInfo.absolutePath() + "/" + newName;
        if (QFile::rename(path, newPath)) {
            refreshView();
        } else {
            QMessageBox::critical(this, "Error", "Could not rename file/folder.");
        }
    }
}

void AstrumFileManager::copySelected() {
    QString path = file_icon_view->getSelectedPath();
    if (!path.isEmpty()) {
        clipboard_path = path;
        is_cut = false;
    }
}

void AstrumFileManager::cutSelected() {
    QString path = file_icon_view->getSelectedPath();
    if (!path.isEmpty()) {
        clipboard_path = path;
        is_cut = true;
    }
}

bool AstrumFileManager::copyDirectory(const QString& sourceDir, const QString& destDir) {
    QDir sourceDirectory(sourceDir);
    if (!sourceDirectory.exists()) {
        return false;
    }
    
    QDir destDirectory(destDir);
    if (!destDirectory.exists()) {
        destDirectory.mkdir(destDir);
    }
    
    QStringList files = sourceDirectory.entryList(QDir::Files);
    for (int i = 0; i < files.count(); i++) {
        QString srcName = sourceDir + "/" + files[i];
        QString destName = destDir + "/" + files[i];
        if (!QFile::copy(srcName, destName)) {
            return false;
        }
    }
    
    QStringList dirs = sourceDirectory.entryList(QDir::AllDirs | QDir::NoDotAndDotDot);
    for (int i = 0; i < dirs.count(); i++) {
        QString srcName = sourceDir + "/" + dirs[i];
        QString destName = destDir + "/" + dirs[i];
        if (!copyDirectory(srcName, destName)) {
            return false;
        }
    }
    
    return true;
}

void AstrumFileManager::paste() {
    QString current_path = path_edit->text();
    if (clipboard_path.isEmpty() || current_path.isEmpty()) {
        return;
    }
    
    QFileInfo sourceInfo(clipboard_path);
    if (!sourceInfo.exists()) {
        QMessageBox::critical(this, "Error", "Source file or folder no longer exists.");
        clipboard_path = "";
        return;
    }
    
    QDir destDir(current_path);
    QString destPath = destDir.absoluteFilePath(sourceInfo.fileName());
    
    // Проверяем, существует ли уже файл с таким именем
    if (QFileInfo::exists(destPath) && destPath != clipboard_path) {
        QMessageBox msgBox;
        msgBox.setWindowTitle("File Exists");
        msgBox.setText("A file with the same name already exists. Overwrite?");
        msgBox.setStandardButtons(QMessageBox::Yes | QMessageBox::No);
        msgBox.setDefaultButton(QMessageBox::No);
        msgBox.setIcon(QMessageBox::Question);
        
        msgBox.setStyleSheet(QString(
            "QMessageBox {"
            "   background-color: %1;"
            "   color: %2;"
            "}"
            "QLabel {"
            "   color: %2;"
            "}"
            "QPushButton {"
            "   background-color: %3;"
            "   color: %1;"
            "   border: none;"
            "   border-radius: 4px;"
            "   padding: 6px 12px;"
            "   font-weight: bold;"
            "}"
            "QPushButton:hover {"
            "   background-color: %4;"
            "}"
        ).arg(SURFACE_DARK).arg(TEXT_PRIMARY).arg(ACCENT_COLOR).arg(SECONDARY_ACCENT));
        
        int result = msgBox.exec();
        if (result != QMessageBox::Yes) {
            return;
        }
        
        // Удаляем существующий файл/папку перед копированием/перемещением
        if (QFileInfo(destPath).isDir()) {
            QDir dir(destPath);
            dir.removeRecursively();
        } else {
            QFile::remove(destPath);
        }
    }
    
    bool success = false;
    
    if (is_cut) {
        // Перемещение файла/папки
        success = QFile::rename(clipboard_path, destPath);
        if (success) {
            clipboard_path = "";
        }
    } else {
        // Копирование файла/папки
        if (sourceInfo.isDir()) {
            // Рекурсивное копирование директории
            success = copyDirectory(clipboard_path, destPath);
        } else {
            // Копирование файла
            success = QFile::copy(clipboard_path, destPath);
        }
    }
    
    if (success) {
        refreshView();
    } else {
        QMessageBox::critical(this, "Error", "Failed to paste file or folder.");
    }
}

void AstrumFileManager::showProperties() {
    QString path = file_icon_view->getSelectedPath();
    if (path.isEmpty()) {
        return;
    }
    
    QFileInfo fileInfo(path);
    if (!fileInfo.exists()) {
        return;
    }
    
    QDialog dialog(this);
    dialog.setWindowTitle("Properties");
    dialog.setMinimumWidth(400);
    
    QVBoxLayout* layout = new QVBoxLayout(&dialog);
    
    // Имя и тип
    QLabel* nameLabel = new QLabel("<b>Name:</b> " + fileInfo.fileName());
    layout->addWidget(nameLabel);
    
    QString type;
    if (fileInfo.isFile()) {
        QMimeDatabase mimeDb;
        type = mimeDb.mimeTypeForFile(path).comment();
    } else if (fileInfo.isDir()) {
        type = "Folder";
    } else if (fileInfo.isSymLink()) {
        type = "Symbolic Link";
    } else {
        type = "Unknown";
    }
    
    QLabel* typeLabel = new QLabel("<b>Type:</b> " + type);
    layout->addWidget(typeLabel);
    
    // Полный путь
    QLabel* pathLabel = new QLabel("<b>Location:</b> " + fileInfo.absolutePath());
    pathLabel->setWordWrap(true);
    layout->addWidget(pathLabel);
    
    // Размер
    QString sizeStr;
    if (fileInfo.isFile()) {
        qint64 size = fileInfo.size();
        if (size < 1024) {
            sizeStr = QString("%1 bytes").arg(size);
        } else if (size < 1024 * 1024) {
            sizeStr = QString("%1 KB").arg(size / 1024.0, 0, 'f', 2);
        } else if (size < 1024 * 1024 * 1024) {
            sizeStr = QString("%1 MB").arg(size / (1024.0 * 1024.0), 0, 'f', 2);
        } else {
            sizeStr = QString("%1 GB").arg(size / (1024.0 * 1024.0 * 1024.0), 0, 'f', 2);
        }
    } else if (fileInfo.isDir()) {
        sizeStr = "Calculating..."; // В реальном приложении здесь нужно считать размер директории
    }
    
    QLabel* sizeLabel = new QLabel("<b>Size:</b> " + sizeStr);
    layout->addWidget(sizeLabel);
    
    // Даты создания, изменения и доступа
    QLabel* createdLabel = new QLabel("<b>Created:</b> " + fileInfo.birthTime().toString("yyyy-MM-dd hh:mm:ss"));
    QLabel* modifiedLabel = new QLabel("<b>Modified:</b> " + fileInfo.lastModified().toString("yyyy-MM-dd hh:mm:ss"));
    QLabel* accessedLabel = new QLabel("<b>Accessed:</b> " + fileInfo.lastRead().toString("yyyy-MM-dd hh:mm:ss"));
    
    layout->addWidget(createdLabel);
    layout->addWidget(modifiedLabel);
    layout->addWidget(accessedLabel);
    
    // Права доступа
    QString permissions;
    if (fileInfo.isReadable()) permissions += "R";
    if (fileInfo.isWritable()) permissions += "W";
    if (fileInfo.isExecutable()) permissions += "X";
    
    QLabel* permissionsLabel = new QLabel("<b>Permissions:</b> " + permissions);
    layout->addWidget(permissionsLabel);
    
    // Кнопка закрытия
    QHBoxLayout* buttonLayout = new QHBoxLayout();
    QPushButton* closeButton = new QPushButton("Close");
    connect(closeButton, &QPushButton::clicked, &dialog, &QDialog::accept);
    buttonLayout->addStretch();
    buttonLayout->addWidget(closeButton);
    layout->addLayout(buttonLayout);
    
    // Стили
    dialog.setStyleSheet(QString(
        "QDialog {"
        "   background-color: %1;"
        "   color: %2;"
        "}"
        "QLabel {"
        "   color: %2;"
        "   padding: 5px;"
        "}"
        "QPushButton {"
        "   background-color: %3;"
        "   color: %1;"
        "   border: none;"
        "   border-radius: 4px;"
        "   padding: 6px 12px;"
        "   font-weight: bold;"
        "}"
        "QPushButton:hover {"
        "   background-color: %4;"
        "}"
    ).arg(SURFACE_DARK).arg(TEXT_PRIMARY).arg(ACCENT_COLOR).arg(SECONDARY_ACCENT));
    
    dialog.exec();
}

void AstrumFileManager::openWith() {
    QString path = file_icon_view->getSelectedPath();
    if (path.isEmpty()) {
        return;
    }
    
    QString program = QFileDialog::getOpenFileName(this, "Select Program", "/usr/bin", "All Files (*)");
    if (!program.isEmpty()) {
        QStringList arguments;
        arguments << path;
        QProcess::startDetached(program, arguments);
    }
}

void AstrumFileManager::openContainingFolder() {
    QString path = file_icon_view->getSelectedPath();
    if (path.isEmpty()) {
        return;
    }
    
    QFileInfo fileInfo(path);
    displayDirectoryContents(fileInfo.absolutePath());
}

void AstrumFileManager::openInTerminal() {
    QString path = file_icon_view->getSelectedPath();
    if (path.isEmpty()) {
        path = path_edit->text();
    }
    
    if (!QFileInfo(path).isDir()) {
        QFileInfo fileInfo(path);
        path = fileInfo.absolutePath();
    }
    
    QProcess process;
    process.setWorkingDirectory(path);
    
    // Попытка запустить терминал разными способами
    QStringList terminals = {
        "x-terminal-emulator", // Debian/Ubuntu
        "gnome-terminal", // GNOME
        "konsole", // KDE
        "xfce4-terminal", // XFCE
        "terminator", // Terminator
        "alacritty", // Alacritty
        "xterm", // универсальный вариант
    };
    
    for (const QString& terminal : terminals) {
        if (process.startDetached(terminal, QStringList())) {
            return;
        }
    }
    
    QMessageBox::warning(this, "Error", "Could not open terminal.");
}

void AstrumFileManager::showAboutDialog() {
    QDialog dialog(this);
    dialog.setWindowTitle("About Astrum");
    dialog.setMinimumWidth(450);
    dialog.setMinimumHeight(380);
    
    QVBoxLayout* layout = new QVBoxLayout(&dialog);
    
    // Заголовок с логотипом
    QHBoxLayout* headerLayout = new QHBoxLayout();
    
    QLabel* iconLabel = new QLabel();
    iconLabel->setPixmap(QIcon::fromTheme("system-file-manager").pixmap(64, 64));
    headerLayout->addWidget(iconLabel);
    
    QVBoxLayout* titleLayout = new QVBoxLayout();
    QLabel* titleLabel = new QLabel("<h1>Astrum File Manager</h1>");
    titleLabel->setStyleSheet(QString("color: %1;").arg(ACCENT_COLOR));
    titleLayout->addWidget(titleLabel);
    
    QLabel* versionLabel = new QLabel("<h3>Version 1.3.3</h3>");
    versionLabel->setStyleSheet(QString("color: %1;").arg(TEXT_PRIMARY));
    titleLayout->addWidget(versionLabel);
    
    headerLayout->addLayout(titleLayout);
    headerLayout->addStretch();
    layout->addLayout(headerLayout);
    
    // Линия разделителя
    QFrame* line = new QFrame();
    line->setFrameShape(QFrame::HLine);
    line->setFrameShadow(QFrame::Sunken);
    line->setStyleSheet(QString("background-color: %1;").arg(DIVIDER_COLOR));
    layout->addWidget(line);
    
    // Информация о программе
    QLabel* infoLabel = new QLabel();
    infoLabel->setWordWrap(true);
    infoLabel->setAlignment(Qt::AlignLeft | Qt::AlignTop);
    infoLabel->setTextFormat(Qt::RichText);
    infoLabel->setText(
        "<p><b>Astrum File Manager</b> is a minimalist dark-themed file manager.</p>"
        "<p><b>License:</b> GNU GPL v3.0</p>"
        "<p><b>Developer:</b> AnmiTaliDev</p>"
        "<p><b>Created for:</b> NurOS AetherApps</p>"
        "<p>This program is free software: you can redistribute it and/or modify "
        "it under the terms of the GNU General Public License as published by "
        "the Free Software Foundation, either version 3 of the License, or "
        "(at your option) any later version.</p>"
        "<p>This program is distributed in the hope that it will be useful, "
        "but WITHOUT ANY WARRANTY; without even the implied warranty of "
        "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the "
        "GNU General Public License for more details.</p>"
    );
    infoLabel->setStyleSheet(QString("color: %1; padding: 10px;").arg(TEXT_PRIMARY));
    layout->addWidget(infoLabel);
    
    // Кнопка закрытия
    QHBoxLayout* buttonLayout = new QHBoxLayout();
    QPushButton* closeButton = new QPushButton("Close");
    connect(closeButton, &QPushButton::clicked, &dialog, &QDialog::accept);
    closeButton->setStyleSheet(QString(
        "QPushButton {"
        "   background-color: %1;"
        "   color: %2;"
        "   border: none;"
        "   border-radius: 4px;"
        "   padding: 8px 16px;"
        "   font-weight: bold;"
        "}"
        "QPushButton:hover {"
        "   background-color: %3;"
        "}"
    ).arg(ACCENT_COLOR).arg(BG_DARK).arg(SECONDARY_ACCENT));
    buttonLayout->addStretch();
    buttonLayout->addWidget(closeButton);
    layout->addLayout(buttonLayout);
    
    // Стили для диалога
    dialog.setStyleSheet(QString(
        "QDialog {"
        "   background-color: %1;"
        "   color: %2;"
        "   border-radius: 8px;"
        "}"
        "QLabel {"
        "   color: %2;"
        "}"
    ).arg(SURFACE_DARK).arg(TEXT_PRIMARY));
    
    dialog.exec();
}

void AstrumFileManager::bookmarkClicked(QListWidgetItem* item) {
    QString path = item->data(Qt::UserRole).toString();
    displayDirectoryContents(path);
}

void AstrumFileManager::fileItemClicked(const QString& path) {
    QFileInfo fileInfo(path);
    if (fileInfo.isDir()) {
        displayDirectoryContents(path);
    } else if (fileInfo.isFile()) {
        openFile(path);
    }
}

void AstrumFileManager::fileItemRightClicked(const QString& path, const QPoint& pos) {
    QMenu* context_menu = nullptr;
    
    if (path.isEmpty()) {
        // Клик по пустой области
        context_menu = createEmptyAreaContextMenu();
    } else {
        QFileInfo fileInfo(path);
        if (fileInfo.isDir()) {
            // Клик по директории
            context_menu = createDirectoryContextMenu(path);
        } else {
            // Клик по файлу
            context_menu = createFileContextMenu(path);
        }
    }
    
    if (context_menu) {
        context_menu->exec(pos);
        delete context_menu; // Удаляем меню после использования
    }
}

// Создание контекстного меню для файла
QMenu* AstrumFileManager::createFileContextMenu(const QString& path) {
    QMenu* menu = new QMenu(this);
    
    QFileInfo fileInfo(path);
    QMimeDatabase mimeDb;
    QString mimeType = mimeDb.mimeTypeForFile(path).name();
    
    // Открыть
    QAction* openAction = new QAction(QIcon::fromTheme("document-open"), "Open", this);
    connect(openAction, &QAction::triggered, [this, path]() {
        openFile(path);
    });
    menu->addAction(openAction);
    
    // Открыть с помощью...
    QAction* openWithAction = new QAction(QIcon::fromTheme("document-open"), "Open with...", this);
    connect(openWithAction, &QAction::triggered, this, &AstrumFileManager::openWith);
    menu->addAction(openWithAction);
    
    // Открыть содержащую папку
    QAction* openFolderAction = new QAction(QIcon::fromTheme("folder-open"), "Open containing folder", this);
    connect(openFolderAction, &QAction::triggered, this, &AstrumFileManager::openContainingFolder);
    menu->addAction(openFolderAction);
    
    menu->addSeparator();
    
    // Копировать
    QAction* copyAction = new QAction(QIcon::fromTheme("edit-copy"), "Copy", this);
    connect(copyAction, &QAction::triggered, this, &AstrumFileManager::copySelected);
    menu->addAction(copyAction);
    
    // Вырезать
    QAction* cutAction = new QAction(QIcon::fromTheme("edit-cut"), "Cut", this);
    connect(cutAction, &QAction::triggered, this, &AstrumFileManager::cutSelected);
    menu->addAction(cutAction);
    
    menu->addSeparator();
    
    // Переименовать
    QAction* renameAction = new QAction(QIcon::fromTheme("edit-rename"), "Rename", this);
    connect(renameAction, &QAction::triggered, this, &AstrumFileManager::renameSelected);
    menu->addAction(renameAction);
    
    // Удалить
    QAction* deleteAction = new QAction(QIcon::fromTheme("edit-delete"), "Delete", this);
    connect(deleteAction, &QAction::triggered, this, &AstrumFileManager::deleteSelected);
    menu->addAction(deleteAction);
    
    menu->addSeparator();
    
    // Свойства
    QAction* propertiesAction = new QAction(QIcon::fromTheme("document-properties"), "Properties", this);
    connect(propertiesAction, &QAction::triggered, this, &AstrumFileManager::showProperties);
    menu->addAction(propertiesAction);
    
    // Применяем стили к меню
    menu->setStyleSheet(QString(
        "QMenu {"
        "   background-color: %1;"
        "   color: %2;"
        "   border: 1px solid %3;"
        "   border-radius: 4px;"
        "   padding: 4px;"
        "}"
        "QMenu::item {"
        "   padding: 6px 24px 6px 12px;"
        "   border-radius: 2px;"
        "}"
        "QMenu::item:selected {"
        "   background-color: rgba(255, 255, 255, 0.1);"
        "}"
    ).arg(SURFACE_DARK).arg(TEXT_PRIMARY).arg(DIVIDER_COLOR));
    
    return menu;
}

// Создание контекстного меню для директории
QMenu* AstrumFileManager::createDirectoryContextMenu(const QString& path) {
    QMenu* menu = new QMenu(this);
    
    // Открыть
    QAction* openAction = new QAction(QIcon::fromTheme("folder-open"), "Open", this);
    connect(openAction, &QAction::triggered, [this, path]() {
        displayDirectoryContents(path);
    });
    menu->addAction(openAction);
    
    // Открыть в терминале
    QAction* openTerminalAction = new QAction(QIcon::fromTheme("utilities-terminal"), "Open in Terminal", this);
    connect(openTerminalAction, &QAction::triggered, this, &AstrumFileManager::openInTerminal);
    menu->addAction(openTerminalAction);
    
    menu->addSeparator();
    
    // Копировать
    QAction* copyAction = new QAction(QIcon::fromTheme("edit-copy"), "Copy", this);
    connect(copyAction, &QAction::triggered, this, &AstrumFileManager::copySelected);
    menu->addAction(copyAction);
    
    // Вырезать
    QAction* cutAction = new QAction(QIcon::fromTheme("edit-cut"), "Cut", this);
    connect(cutAction, &QAction::triggered, this, &AstrumFileManager::cutSelected);
    menu->addAction(cutAction);
    
    // Вставить (активно только если буфер обмена не пуст)
    QAction* pasteAction = new QAction(QIcon::fromTheme("edit-paste"), "Paste", this);
    connect(pasteAction, &QAction::triggered, this, &AstrumFileManager::paste);
    pasteAction->setEnabled(!clipboard_path.isEmpty());
    menu->addAction(pasteAction);
    
    menu->addSeparator();
    
    // Создать новую папку
    QAction* newFolderAction = new QAction(QIcon::fromTheme("folder-new"), "New Folder", this);
    connect(newFolderAction, &QAction::triggered, this, &AstrumFileManager::createNewFolder);
    menu->addAction(newFolderAction);
    
    menu->addSeparator();
    
    // Переименовать
    QAction* renameAction = new QAction(QIcon::fromTheme("edit-rename"), "Rename", this);
    connect(renameAction, &QAction::triggered, this, &AstrumFileManager::renameSelected);
    menu->addAction(renameAction);
    
    // Удалить
    QAction* deleteAction = new QAction(QIcon::fromTheme("edit-delete"), "Delete", this);
    connect(deleteAction, &QAction::triggered, this, &AstrumFileManager::deleteSelected);
    menu->addAction(deleteAction);
    
    menu->addSeparator();
    
    // Свойства
    QAction* propertiesAction = new QAction(QIcon::fromTheme("document-properties"), "Properties", this);
    connect(propertiesAction, &QAction::triggered, this, &AstrumFileManager::showProperties);
    menu->addAction(propertiesAction);
    
    // Применяем стили к меню
    menu->setStyleSheet(QString(
        "QMenu {"
        "   background-color: %1;"
        "   color: %2;"
        "   border: 1px solid %3;"
        "   border-radius: 4px;"
        "   padding: 4px;"
        "}"
        "QMenu::item {"
        "   padding: 6px 24px 6px 12px;"
        "   border-radius: 2px;"
        "}"
        "QMenu::item:selected {"
        "   background-color: rgba(255, 255, 255, 0.1);"
        "}"
    ).arg(SURFACE_DARK).arg(TEXT_PRIMARY).arg(DIVIDER_COLOR));
    
    return menu;
}

// Создание контекстного меню для пустой области
QMenu* AstrumFileManager::createEmptyAreaContextMenu() {
    QMenu* menu = new QMenu(this);
    
    // Новая папка
    QAction* newFolderAction = new QAction(QIcon::fromTheme("folder-new"), "New Folder", this);
    connect(newFolderAction, &QAction::triggered, this, &AstrumFileManager::createNewFolder);
    menu->addAction(newFolderAction);
    
    // Вставить (активно только если буфер обмена не пуст)
    QAction* pasteAction = new QAction(QIcon::fromTheme("edit-paste"), "Paste", this);
    connect(pasteAction, &QAction::triggered, this, &AstrumFileManager::paste);
    pasteAction->setEnabled(!clipboard_path.isEmpty());
    menu->addAction(pasteAction);
    
    menu->addSeparator();
    
    // Обновить
    QAction* refreshAction = new QAction(QIcon::fromTheme("view-refresh"), "Refresh", this);
    connect(refreshAction, &QAction::triggered, this, &AstrumFileManager::refreshView);
    menu->addAction(refreshAction);
    
    // Применяем стили к меню
    menu->setStyleSheet(QString(
        "QMenu {"
        "   background-color: %1;"
        "   color: %2;"
        "   border: 1px solid %3;"
        "   border-radius: 4px;"
        "   padding: 4px;"
        "}"
        "QMenu::item {"
        "   padding: 6px 24px 6px 12px;"
        "   border-radius: 2px;"
        "}"
        "QMenu::item:selected {"
        "   background-color: rgba(255, 255, 255, 0.1);"
        "}"
    ).arg(SURFACE_DARK).arg(TEXT_PRIMARY).arg(DIVIDER_COLOR));
    
    return menu;
}

void AstrumFileManager::applyFilter() {
    QString current_path = path_edit->text();
    QFileInfo fileInfo(current_path);
    
    if (fileInfo.isDir() && fileInfo.isReadable()) {
        QString filter_text = filter_edit->text();
        QString filter_mode = filter_type->currentData().toString();
        
        if (filter_text.isEmpty()) {
            // Если фильтр пуст, просто обновляем вид
            refreshView();
            return;
        }
        
        QDir dir(current_path);
        QStringList entries = dir.entryList(QDir::AllEntries | QDir::NoDotAndDotDot);
        
        file_icon_view->clear();
        
        for (const QString& entry : entries) {
            QString entryPath = dir.absoluteFilePath(entry);
            QFileInfo entryInfo(entryPath);
            
            bool shouldShow = false;
            
            if (filter_mode == "name") {
                // Фильтр по имени файла
                shouldShow = entry.contains(filter_text, Qt::CaseInsensitive);
            }
            else if (filter_mode == "type") {
                // Фильтр по типу файла (расширению)
                if (entryInfo.isDir()) {
                    shouldShow = filter_text.compare("folder", Qt::CaseInsensitive) == 0 ||
                                 filter_text.compare("directory", Qt::CaseInsensitive) == 0;
                } else {
                    QString suffix = entryInfo.suffix();
                    shouldShow = !suffix.isEmpty() && suffix.contains(filter_text, Qt::CaseInsensitive);
                }
            }
            else if (filter_mode == "size") {
                // Фильтр по размеру
                if (entryInfo.isFile()) {
                    // Преобразуем фильтр в байты. Формат может быть: >5MB, <2KB, =1GB
                    QString sizeText = filter_text.trimmed();
                    QChar comparisonOp = '='; // По умолчанию - равно
                    
                    if (sizeText.startsWith('>') || sizeText.startsWith('<') || sizeText.startsWith('=')) {
                        comparisonOp = sizeText.at(0);
                        sizeText = sizeText.mid(1).trimmed();
                    }
                    
                    bool ok = false;
                    double size = 0;
                    qint64 multiplier = 1;
                    
                    // Определяем множитель размера (KB, MB, GB, TB)
                    if (sizeText.endsWith("KB", Qt::CaseInsensitive)) {
                        multiplier = 1024;
                        sizeText = sizeText.left(sizeText.length() - 2);
                    } else if (sizeText.endsWith("MB", Qt::CaseInsensitive)) {
                        multiplier = 1024 * 1024;
                        sizeText = sizeText.left(sizeText.length() - 2);
                    } else if (sizeText.endsWith("GB", Qt::CaseInsensitive)) {
                        multiplier = 1024 * 1024 * 1024;
                        sizeText = sizeText.left(sizeText.length() - 2);
                    } else if (sizeText.endsWith("TB", Qt::CaseInsensitive)) {
                        multiplier = qint64(1024) * 1024 * 1024 * 1024;
                        sizeText = sizeText.left(sizeText.length() - 2);
                    }
                    
                    size = sizeText.toDouble(&ok);
                    
                    if (ok) {
                        qint64 targetSize = qint64(size * multiplier);
                        qint64 fileSize = entryInfo.size();
                        
                        if (comparisonOp == '=') {
                            // Допускаем погрешность в 5% для равенства
                            double ratio = double(fileSize) / targetSize;
                            shouldShow = (ratio >= 0.95 && ratio <= 1.05);
                        } else if (comparisonOp == '>') {
                            shouldShow = (fileSize > targetSize);
                        } else if (comparisonOp == '<') {
                            shouldShow = (fileSize < targetSize);
                        }
                    } else {
                        // Если размер не удалось преобразовать, показываем все файлы
                        shouldShow = true;
                    }
                } else {
                    // Для директорий показываем только если ищем директории
                    shouldShow = filter_text.compare("folder", Qt::CaseInsensitive) == 0 ||
                               filter_text.compare("directory", Qt::CaseInsensitive) == 0;
                }
            }
            
            if (shouldShow) {
                file_icon_view->add_item(entry, entryPath, entryInfo.isDir());
            }
        }
        
        // Обновляем счетчик элементов
        updateItemCount(current_path, true);
    }
}

void AstrumFileManager::clearFilter() {
    filter_edit->clear();
    refreshView();
}

void AstrumFileManager::filterTextChanged(const QString& text) {
    // Автоматическое применение фильтра при изменении текста
    if (text.isEmpty()) {
        refreshView();
    } else {
        applyFilter();
    }
}

QAction* AstrumFileManager::create_action(const QIcon& icon, const QString& tip) {
    QAction* action = new QAction(icon, tip, this);
    action->setStatusTip(tip);
    return action;
}

void AstrumFileManager::add_bookmark(const QIcon& icon, const QString& name, const QString& path) {
    QListWidgetItem* item = new QListWidgetItem(icon, name);
    item->setData(Qt::UserRole, path);
    bookmarks->addItem(item);
}

void AstrumFileManager::applyStyles() {
    // Применение глобальных стилей в стиле нью-минимализм с более темным фоном
    setStyleSheet(QString(
        "QMainWindow {"
        "   background-color: %1;"
        "}"
        "QMenu {"
        "   background-color: %2;"
        "   color: %3;"
        "   border: 1px solid %4;"
        "   border-radius: 4px;"
        "   padding: 4px;"
        "}"
        "QMenu::item {"
        "   padding: 6px 24px 6px 12px;"
        "   border-radius: 2px;"
        "}"
        "QMenu::item:selected {"
        "   background-color: rgba(255, 255, 255, 0.1);" // Немного более видимое подсвечивание
        "}"
        "QMenuBar {"
        "   background-color: %1;"
        "   color: %3;"
        "   border: none;"
        "}"
        "QMenuBar::item {"
        "   padding: 6px 12px;"
        "   background: transparent;"
        "   border-radius: 4px;"
        "}"
        "QMenuBar::item:selected {"
        "   background-color: rgba(255, 255, 255, 0.1);" // Немного более видимое подсвечивание
        "}"
        "QDialog {"
        "   background-color: %2;"
        "   color: %3;"
        "}"
        "QInputDialog {"
        "   background-color: %2;"
        "   color: %3;"
        "}"
    ).arg(BG_DARK).arg(SURFACE_DARK).arg(TEXT_PRIMARY).arg(DIVIDER_COLOR));
}

void AstrumFileManager::connectSignals() {
    connect(back_btn, &QAction::triggered, this, &AstrumFileManager::goBack);
    connect(forward_btn, &QAction::triggered, this, &AstrumFileManager::goForward);
    connect(up_btn, &QAction::triggered, this, &AstrumFileManager::goUp);
    connect(refresh_btn, &QAction::triggered, this, &AstrumFileManager::refreshView);
    connect(new_folder_btn, &QAction::triggered, this, &AstrumFileManager::createNewFolder);
    connect(delete_btn, &QAction::triggered, this, &AstrumFileManager::deleteSelected);
    connect(bookmarks, &QListWidget::itemClicked, this, &AstrumFileManager::bookmarkClicked);
    connect(file_icon_view, &FileIconView::itemClicked, this, &AstrumFileManager::fileItemClicked);
    connect(file_icon_view, &FileIconView::itemRightClicked, this, &AstrumFileManager::fileItemRightClicked);
    connect(filter_btn, &QPushButton::clicked, this, &AstrumFileManager::applyFilter);
    connect(clear_btn, &QPushButton::clicked, this, &AstrumFileManager::clearFilter);
    connect(filter_edit, &QLineEdit::textChanged, this, &AstrumFileManager::filterTextChanged);
}

void AstrumFileManager::createMenu() {
    QMenuBar* menubar = this->menuBar();
    menubar->setObjectName("menuBar");

    // Меню "Файл"
    QMenu* file_menu = menubar->addMenu("File");
    file_menu->setObjectName("menu");

    QAction* new_folder = new QAction("New Folder", this);
    connect(new_folder, &QAction::triggered, this, &AstrumFileManager::createNewFolder);
    file_menu->addAction(new_folder);

    QAction* delete_action = new QAction("Delete", this);
    connect(delete_action, &QAction::triggered, this, &AstrumFileManager::deleteSelected);
    file_menu->addAction(delete_action);

    file_menu->addSeparator();

    QAction* exit_action = new QAction("Exit", this);
    connect(exit_action, &QAction::triggered, this, &QMainWindow::close);
    file_menu->addAction(exit_action);

    // Меню "Правка"
    QMenu* edit_menu = menubar->addMenu("Edit");
    edit_menu->setObjectName("menu");

    QAction* copy_action = new QAction("Copy", this);
    connect(copy_action, &QAction::triggered, this, &AstrumFileManager::copySelected);
    edit_menu->addAction(copy_action);

    QAction* cut_action = new QAction("Cut", this);
    connect(cut_action, &QAction::triggered, this, &AstrumFileManager::cutSelected);
    edit_menu->addAction(cut_action);

    QAction* paste_action = new QAction("Paste", this);
    connect(paste_action, &QAction::triggered, this, &AstrumFileManager::paste);
    edit_menu->addAction(paste_action);

    edit_menu->addSeparator();

    QAction* rename_action = new QAction("Rename", this);
    connect(rename_action, &QAction::triggered, this, &AstrumFileManager::renameSelected);
    edit_menu->addAction(rename_action);

    // Меню "Вид"
    QMenu* view_menu = menubar->addMenu("View");
    view_menu->setObjectName("menu");

    QAction* refresh_action = new QAction("Refresh", this);
    connect(refresh_action, &QAction::triggered, this, &AstrumFileManager::refreshView);
    view_menu->addAction(refresh_action);

    // Меню "Справка"
    QMenu* help_menu = menubar->addMenu("Help");
    help_menu->setObjectName("menu");

    QAction* about_action = new QAction(QIcon::fromTheme("help-about"), "About Astrum", this);
    connect(about_action, &QAction::triggered, this, &AstrumFileManager::showAboutDialog);
    help_menu->addAction(about_action);
}

void AstrumFileManager::updatePath(const QString& path) {
    path_edit->setText(path);
    updateItemCount(path);
}

void AstrumFileManager::updateItemCount(const QString& path, bool filtered) {
    QDir dir(path);
    if (dir.exists()) {
        if (filtered) {
            // Для отфильтрованных элементов подсчитываем количество видимых виджетов
            int count = 0;
            for (int i = 0; i < file_icon_view->layout->count(); i++) {
                if (file_icon_view->layout->itemAt(i)->widget()) {
                    count++;
                }
            }
            items_label->setText(QString("Filtered: %1").arg(count));
        } else {
            // Для всех элементов показываем общее количество
            QStringList entries = dir.entryList(QDir::AllEntries | QDir::NoDotAndDotDot);
            items_label->setText(QString("Items: %1").arg(entries.count()));
        }
    } else {
        items_label->setText("Items: 0");
    }
}

void AstrumFileManager::displayDirectoryContents(const QString& path) {
    updatePath(path);

    QFileInfo fileInfo(path);
    if (fileInfo.isDir() && fileInfo.isReadable()) {
        QDir dir(path);
        QStringList entries = dir.entryList(QDir::AllEntries | QDir::NoDotAndDotDot);
        
        file_icon_view->clear();
        for (const QString& entry : entries) {
            QString entryPath = dir.absoluteFilePath(entry);
            QFileInfo entryInfo(entryPath);
            file_icon_view->add_item(entry, entryPath, entryInfo.isDir());
        }
    } else {
        file_icon_view->clear();
        file_icon_view->add_item("No access", "", false);
    }
}

void AstrumFileManager::openFile(const QString& path) {
    QFileInfo fileInfo(path);
    if (fileInfo.isFile()) {
        #ifdef Q_OS_WIN
            QProcess::startDetached("explorer", QStringList() << path);
        #else
            QProcess::startDetached("xdg-open", QStringList() << path);
        #endif
    }
}

void AstrumFileManager::updateUserInfo() {
    #ifdef Q_OS_WIN
        user_label->setText(QString("User: %1").arg(qgetenv("USERNAME")));
    #else
        user_label->setText(QString("User: %1").arg(qgetenv("USER")));
    #endif
}

// Основная функция
int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    
    // Установка иконки приложения
    app.setWindowIcon(QIcon::fromTheme("system-file-manager"));
    
    AstrumFileManager window;
    window.show();
    return app.exec();
}