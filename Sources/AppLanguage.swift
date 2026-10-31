import Foundation

enum AppLanguage {
    static var identifier: String {
        switch UserDefaults.standard.string(forKey: "bomphim.language") ?? "Tiếng Việt" {
        case "English": return "en"
        case "中文": return "zh-Hans"
        case "日本語": return "ja"
        case "한국어": return "ko"
        case "ไทย": return "th"
        case "Français": return "fr"
        case "Español": return "es"
        default: return "vi"
        }
    }

    static func text(_ vietnamese: String) -> String {
        let language = identifier
        guard language != "vi" else { return vietnamese }
        let translations: [String: [String: String]] = [
            "Trang chủ": ["en":"Home","zh-Hans":"首页","ja":"ホーム","ko":"홈","th":"หน้าหลัก","fr":"Accueil","es":"Inicio"],
            "Tìm kiếm": ["en":"Search","zh-Hans":"搜索","ja":"検索","ko":"검색","th":"ค้นหา","fr":"Rechercher","es":"Buscar"],
            "Thư viện": ["en":"Library","zh-Hans":"片库","ja":"ライブラリ","ko":"보관함","th":"คลัง","fr":"Bibliothèque","es":"Biblioteca"],
            "Cài đặt": ["en":"Settings","zh-Hans":"设置","ja":"設定","ko":"설정","th":"ตั้งค่า","fr":"Paramètres","es":"Ajustes"],
            "Chọn hồ sơ": ["en":"Choose profile","zh-Hans":"选择个人资料","ja":"プロフィールを選択","ko":"프로필 선택","th":"เลือกโปรไฟล์","fr":"Choisir un profil","es":"Elegir perfil"],
            "Chọn hồ sơ để xem thư viện và lịch sử riêng.": ["en":"Choose a profile to see its own library and watch history.","zh-Hans":"选择个人资料以查看专属片库和观看记录。","ja":"プロフィールごとのライブラリと視聴履歴を表示します。","ko":"프로필별 보관함과 시청 기록을 확인하세요.","th":"เลือกโปรไฟล์เพื่อดูคลังและประวัติการรับชม","fr":"Choisissez un profil pour accéder à sa bibliothèque et son historique.","es":"Elige un perfil para ver su biblioteca e historial."],
            "Nhập mã PIN hồ sơ": ["en":"Enter profile PIN","zh-Hans":"输入个人资料 PIN","ja":"プロフィールPINを入力","ko":"프로필 PIN 입력","th":"กรอก PIN โปรไฟล์","fr":"Saisir le code PIN du profil","es":"Introduce el PIN del perfil"],
            "Mở hồ sơ": ["en":"Unlock profile","zh-Hans":"解锁个人资料","ja":"プロフィールを解除","ko":"프로필 잠금 해제","th":"ปลดล็อกโปรไฟล์","fr":"Déverrouiller le profil","es":"Desbloquear perfil"],
            "Mã PIN không chính xác.": ["en":"Incorrect PIN.","zh-Hans":"PIN 不正确。","ja":"PINが正しくありません。","ko":"PIN이 올바르지 않습니다.","th":"PIN ไม่ถูกต้อง","fr":"Code PIN incorrect.","es":"PIN incorrecto."],
            "Mới cập nhật": ["en":"Recently updated","zh-Hans":"最近更新","ja":"最近更新","ko":"최신 업데이트","th":"อัปเดตล่าสุด","fr":"Récemment ajoutés","es":"Actualizados recientemente"],
            "Đang tải phim…": ["en":"Loading movies…","zh-Hans":"正在加载影片…","ja":"作品を読み込み中…","ko":"영화를 불러오는 중…","th":"กำลังโหลดภาพยนตร์…","fr":"Chargement des films…","es":"Cargando películas…"],
            "Chưa tải được phim": ["en":"Couldn't load movies","zh-Hans":"无法加载影片","ja":"作品を読み込めません","ko":"영화를 불러오지 못했습니다","th":"โหลดภาพยนตร์ไม่ได้","fr":"Impossible de charger les films","es":"No se pudieron cargar las películas"],
            "Thử lại": ["en":"Try again","zh-Hans":"重试","ja":"再試行","ko":"다시 시도","th":"ลองอีกครั้ง","fr":"Réessayer","es":"Reintentar"],
            "ĐỀ XUẤT HÔM NAY": ["en":"FEATURED TODAY","zh-Hans":"今日推荐","ja":"本日のおすすめ","ko":"오늘의 추천","th":"แนะนำวันนี้","fr":"À LA UNE","es":"DESTACADO DE HOY"],
            "Xem chi tiết": ["en":"View details","zh-Hans":"查看详情","ja":"詳細を見る","ko":"자세히 보기","th":"ดูรายละเอียด","fr":"Voir les détails","es":"Ver detalles"],
            "Tên phim bạn muốn tìm…": ["en":"Search for a movie…","zh-Hans":"搜索电影…","ja":"作品を検索…","ko":"영화 검색…","th":"ค้นหาภาพยนตร์…","fr":"Rechercher un film…","es":"Buscar una película…"],
            "Tìm phim": ["en":"Find movies","zh-Hans":"查找影片","ja":"作品を探す","ko":"영화 찾기","th":"ค้นหาภาพยนตร์","fr":"Trouver des films","es":"Buscar películas"],
            "Nhập tên phim rồi nhấn Tìm trên bàn phím.": ["en":"Enter a title and press Search on the keyboard.","zh-Hans":"输入片名，然后按键盘上的搜索键。","ja":"作品名を入力してキーボードの検索を押してください。","ko":"영화 제목을 입력하고 키보드에서 검색을 누르세요.","th":"พิมพ์ชื่อเรื่องแล้วกดค้นหาบนแป้นพิมพ์","fr":"Saisissez un titre puis appuyez sur Rechercher.","es":"Escribe un título y pulsa Buscar."],
            "Đang tải danh sách tập…": ["en":"Loading episodes…","zh-Hans":"正在加载剧集…","ja":"エピソードを読み込み中…","ko":"에피소드 불러오는 중…","th":"กำลังโหลดตอน…","fr":"Chargement des épisodes…","es":"Cargando episodios…"],
            "Chọn tập phim": ["en":"Choose an episode","zh-Hans":"选择剧集","ja":"エピソードを選択","ko":"에피소드 선택","th":"เลือกตอน","fr":"Choisir un épisode","es":"Elegir episodio"],
            "Đường dẫn video không hợp lệ.": ["en":"Invalid video URL.","zh-Hans":"视频链接无效。","ja":"動画URLが無効です。","ko":"동영상 URL이 올바르지 않습니다.","th":"URL วิดีโอไม่ถูกต้อง","fr":"URL vidéo invalide.","es":"URL de vídeo no válida."],
            "Yêu thích": ["en":"Favorites","zh-Hans":"收藏","ja":"お気に入り","ko":"즐겨찾기","th":"รายการโปรด","fr":"Favoris","es":"Favoritos"],
            "Chưa có phim yêu thích": ["en":"No favorite movies yet","zh-Hans":"暂无收藏影片","ja":"お気に入りの作品はありません","ko":"즐겨찾는 영화가 없습니다","th":"ยังไม่มีภาพยนตร์โปรด","fr":"Aucun film favori","es":"Aún no hay favoritos"],
            "Đã xem": ["en":"Watched","zh-Hans":"已观看","ja":"視聴済み","ko":"시청함","th":"รับชมแล้ว","fr":"Vus","es":"Vistos"],
            "Lịch sử xem đang trống": ["en":"Watch history is empty","zh-Hans":"观看记录为空","ja":"視聴履歴は空です","ko":"시청 기록이 비어 있습니다","th":"ประวัติการรับชมว่างเปล่า","fr":"L'historique est vide","es":"El historial está vacío"],
            "Ngôn ngữ": ["en":"Language","zh-Hans":"语言","ja":"言語","ko":"언어","th":"ภาษา","fr":"Langue","es":"Idioma"],
            "Ngôn ngữ ứng dụng": ["en":"App language","zh-Hans":"应用语言","ja":"アプリの言語","ko":"앱 언어","th":"ภาษาของแอป","fr":"Langue de l’application","es":"Idioma de la aplicación"],
            "Hồ sơ người dùng": ["en":"User profiles","zh-Hans":"用户资料","ja":"ユーザープロフィール","ko":"사용자 프로필","th":"โปรไฟล์ผู้ใช้","fr":"Profils utilisateur","es":"Perfiles de usuario"],
            "Sử dụng hồ sơ": ["en":"Use profiles","zh-Hans":"启用个人资料","ja":"プロフィールを使用","ko":"프로필 사용","th":"ใช้โปรไฟล์","fr":"Utiliser les profils","es":"Usar perfiles"],
            "Tên hồ sơ": ["en":"Profile name","zh-Hans":"资料名称","ja":"プロフィール名","ko":"프로필 이름","th":"ชื่อโปรไฟล์","fr":"Nom du profil","es":"Nombre del perfil"],
            "Mã PIN hồ sơ": ["en":"Profile PIN","zh-Hans":"资料 PIN","ja":"プロフィールPIN","ko":"프로필 PIN","th":"PIN โปรไฟล์","fr":"Code PIN du profil","es":"PIN del perfil"],
            "Đã thiết lập": ["en":"Set","zh-Hans":"已设置","ja":"設定済み","ko":"설정됨","th":"ตั้งค่าแล้ว","fr":"Configuré","es":"Configurado"],
            "Chưa thiết lập": ["en":"Not set","zh-Hans":"未设置","ja":"未設定","ko":"설정 안 됨","th":"ยังไม่ได้ตั้งค่า","fr":"Non configuré","es":"No configurado"],
            "Nhập mã PIN (4–8 số)": ["en":"Enter PIN (4–8 digits)","zh-Hans":"输入 PIN（4–8 位）","ja":"PINを入力（4～8桁）","ko":"PIN 입력 (4~8자리)","th":"กรอก PIN (4–8 หลัก)","fr":"Saisir le PIN (4 à 8 chiffres)","es":"Introduce el PIN (4–8 dígitos)"],
            "Nhập lại mã PIN": ["en":"Confirm PIN","zh-Hans":"再次输入 PIN","ja":"PINを再入力","ko":"PIN 다시 입력","th":"กรอก PIN อีกครั้ง","fr":"Confirmer le PIN","es":"Repite el PIN"],
            "Đổi mã PIN": ["en":"Change PIN","zh-Hans":"更改 PIN","ja":"PINを変更","ko":"PIN 변경","th":"เปลี่ยน PIN","fr":"Changer le PIN","es":"Cambiar PIN"],
            "Lưu mã PIN": ["en":"Save PIN","zh-Hans":"保存 PIN","ja":"PINを保存","ko":"PIN 저장","th":"บันทึก PIN","fr":"Enregistrer le PIN","es":"Guardar PIN"],
            "Xóa mã PIN": ["en":"Remove PIN","zh-Hans":"删除 PIN","ja":"PINを削除","ko":"PIN 삭제","th":"ลบ PIN","fr":"Supprimer le PIN","es":"Eliminar PIN"],
            "Tên hồ sơ mới": ["en":"New profile name","zh-Hans":"新资料名称","ja":"新しいプロフィール名","ko":"새 프로필 이름","th":"ชื่อโปรไฟล์ใหม่","fr":"Nom du nouveau profil","es":"Nombre del nuevo perfil"],
            "Thêm": ["en":"Add","zh-Hans":"添加","ja":"追加","ko":"추가","th":"เพิ่ม","fr":"Ajouter","es":"Añadir"],
            "Giao diện": ["en":"Appearance","zh-Hans":"外观","ja":"外観","ko":"화면","th":"รูปลักษณ์","fr":"Apparence","es":"Apariencia"],
            "Chủ đề": ["en":"Theme","zh-Hans":"主题","ja":"テーマ","ko":"테마","th":"ธีม","fr":"Thème","es":"Tema"],
            "Sở thích phim của hồ sơ": ["en":"Profile movie preferences","zh-Hans":"资料观影偏好","ja":"プロフィールの映画の好み","ko":"프로필 영화 취향","th":"ความชอบภาพยนตร์ของโปรไฟล์","fr":"Préférences cinéma du profil","es":"Preferencias de películas del perfil"]
        ]
        return translations[vietnamese]?[language] ?? vietnamese
    }
}

func T(_ vietnamese: String) -> String { AppLanguage.text(vietnamese) }
