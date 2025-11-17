.PHONY: help build-macos install-macos run-macos clean-macos build-android run-android clean test

# デフォルトターゲット
help:
	@echo "RemoteTouch Makefile Commands:"
	@echo ""
	@echo "macOS Commands:"
	@echo "  make build-macos      - Build macOS release app"
	@echo "  make install-macos    - Build and install macOS app to /Applications"
	@echo "  make run-macos        - Run macOS app from /Applications"
	@echo "  make clean-macos      - Clean macOS build artifacts"
	@echo ""
	@echo "Android Commands:"
	@echo "  make build-android    - Build Android APK"
	@echo "  make run-android      - Run Android app on connected device"
	@echo ""
	@echo "Other Commands:"
	@echo "  make clean            - Clean all build artifacts"
	@echo "  make test             - Run tests"
	@echo "  make deps             - Get Flutter dependencies"

# macOSアプリのビルド
build-macos:
	@echo "Building macOS release app..."
	flutter build macos --release

# macOSアプリのインストール
install-macos: build-macos
	@echo "Installing macOS app to /Applications..."
	@if [ -d "/Applications/remote_touch.app" ]; then \
		echo "Removing existing app..."; \
		rm -rf /Applications/remote_touch.app; \
	fi
	cp -R build/macos/Build/Products/Release/remote_touch.app /Applications/
	@echo "Installation complete!"
	@echo "You can launch the app from Spotlight (Cmd+Space) or Applications folder"

# macOSアプリの実行
run-macos:
	@if [ ! -d "/Applications/remote_touch.app" ]; then \
		echo "App not installed. Run 'make install-macos' first."; \
		exit 1; \
	fi
	@echo "Launching RemoteTouch..."
	open /Applications/remote_touch.app

# macOSアプリのアンインストール
uninstall-macos:
	@if [ -d "/Applications/remote_touch.app" ]; then \
		echo "Removing RemoteTouch from /Applications..."; \
		rm -rf /Applications/remote_touch.app; \
		echo "Uninstalled successfully!"; \
	else \
		echo "RemoteTouch is not installed."; \
	fi

# macOSビルドのクリーン
clean-macos:
	@echo "Cleaning macOS build artifacts..."
	flutter clean
	rm -rf build/macos

# Androidアプリのビルド
build-android:
	@echo "Building Android APK..."
	flutter build apk --release

# Androidアプリの実行（デバッグ）
run-android:
	@echo "Running Android app on connected device..."
	flutter run -d android

# 全ビルドのクリーン
clean:
	@echo "Cleaning all build artifacts..."
	flutter clean
	rm -rf build/

# テストの実行
test:
	@echo "Running tests..."
	flutter test

# 依存関係の取得
deps:
	@echo "Getting Flutter dependencies..."
	flutter pub get
	@echo "Installing iOS pods..."
	cd ios && pod install
	@echo "Dependencies installed!"

# 開発用：macOSアプリをデバッグモードで実行
dev-macos:
	@echo "Running macOS app in debug mode..."
	flutter run -d macos

# 開発用：Androidアプリをデバッグモードで実行
dev-android:
	@echo "Running Android app in debug mode..."
	flutter run -d android

# 開発用：ホットリロード
watch:
	@echo "Starting Flutter in watch mode..."
	flutter run

# リリースビルド（すべて）
release-all: build-macos build-android
	@echo "All release builds complete!"
	@echo "macOS: build/macos/Build/Products/Release/remote_touch.app"
	@echo "Android: build/app/outputs/flutter-apk/app-release.apk"
