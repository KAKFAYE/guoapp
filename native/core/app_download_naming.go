package core

import (
	"fmt"
	"strings"
)

// sanitizeDownloadName 将剧名等文本转换为可安全用作文件夹/文件名的形式。
func sanitizeDownloadName(name string) string {
	name = strings.TrimSpace(name)
	var b strings.Builder
	for _, r := range name {
		if r < 0x20 || strings.ContainsRune(`<>:"/\|?*`, r) {
			b.WriteRune(' ')
			continue
		}
		b.WriteRune(r)
	}
	name = strings.TrimSpace(b.String())
	for len(name) > 0 && (name[len(name)-1] == '.' || name[len(name)-1] == ' ') {
		name = name[:len(name)-1]
	}
	const maxRunes = 80
	if runes := []rune(name); len(runes) > maxRunes {
		name = strings.TrimRight(string(runes[:maxRunes]), ". ")
	}
	if name == "" {
		return "未命名"
	}
	return name
}

func downloadEpisodeFolder(index int) string {
	return fmt.Sprintf("第%03d集", index)
}

func downloadEpisodeFile(index int) string {
	return fmt.Sprintf("第%03d集.mp4", index)
}

// validDownloadPathElement 判断单个路径元素是否安全可用。
func validDownloadPathElement(name string) bool {
	if name == "" || name == "." || name == ".." {
		return false
	}
	if strings.ContainsAny(name, "<>:\"/\\|?*") {
		return false
	}
	trimmed := strings.TrimSpace(name)
	switch strings.ToLower(trimmed) {
	case "con", "prn", "aux", "nul":
		return false
	}
	for i := 1; i <= 9; i++ {
		if strings.ToLower(trimmed) == fmt.Sprintf("com%d", i) ||
			strings.ToLower(trimmed) == fmt.Sprintf("lpt%d", i) {
			return false
		}
	}
	return true
}

// validDownloadFolder 判断任务记录里的相对下载目录是否安全。
func validDownloadFolder(folder string) bool {
	if folder == "" {
		return false
	}
	for _, element := range strings.Split(folder, "/") {
		if !validDownloadPathElement(element) {
			return false
		}
	}
	return true
}

// validDownloadFile 判断任务记录里的文件名是否安全。
func validDownloadFile(name string) bool {
	return validDownloadPathElement(name) &&
		(strings.HasSuffix(name, ".mp4") || strings.HasSuffix(name, ".m3u8"))
}
