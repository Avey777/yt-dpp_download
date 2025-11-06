#!/usr/bin/env -S v run

import os
import flag

// 自动转义命令参数，防止 shell 特殊字符问题
fn shell_escape(arg string) string {
	escaped := arg.replace("'", "'\\''")
	return "'${escaped}'"
}

mut fp := flag.new_flag_parser(os.args)
fp.application('yt-downloader')
fp.description('YouTube视频下载工具')
fp.skip_executable()

url_arg := fp.string('url', `u`, '', '要下载的视频URL（必需）')
retries := fp.int('retries', `r`, 10000, '重试次数（默认10000次）')
use_custom_ua := fp.bool('user_agent', `a`, false, '使用自定义User-Agent（可能影响速度）')

additional_args := fp.finalize() or {
	println(err)
	println('')
	println('使用方法:')
	println('  v run yt_downloader.vsh --url <YouTube视频URL> [--retries 10000] [--user_agent]')
	println('示例:')
	println('  v run yt_downloader.vsh --url "https://www.youtube.com/watch?v=eng3Gp2CW3g" --retries 10000')
	println('  v run yt_downloader.vsh --url "https://www.youtube.com/watch?v=eng3Gp2CW3g" --user_agent')
	exit(1)
}

// 处理 URL 输入优先级: 参数 > 额外参数 > 用户输入
mut url := url_arg
if url == '' {
	if additional_args.len > 0 {
		url = additional_args[0]
	} else {
		println('请输入YouTube视频URL:')
		url = os.input('URL: ')
	}
}

if url.trim_space() == '' {
	println('错误: 必须提供视频URL')
	exit(1)
}

// 检查 yt-dlp 是否存在
if os.execute('which yt-dlp').exit_code != 0 {
	println('错误: 未找到 yt-dlp，请先安装:')
	println('curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp && chmod a+rx /usr/local/bin/yt-dlp')
	println('或')
	println('pip3 install -U "yt-dlp[default]"')
	exit(1)
}

// 组装命令参数
mut cmd_parts := [
	'yt-dlp',
	'--no-mtime',
	'--newline',
	'--cookies-from-browser', 'edge',
	'--retries', retries.str(),
]

if use_custom_ua {
	user_agent := 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36'
	cmd_parts << ['--user-agent', user_agent]
	println('⚠️  使用自定义User-Agent（可能影响下载速度）')
}

cmd_parts << url

// 拼接命令，安全转义
escaped_parts := cmd_parts.map(shell_escape(it))
cmd_str := escaped_parts.join(' ')

println('正在下载: $url')
println('重试次数: $retries 次')
println('命令: $cmd_str')
println('')
println('开始下载... (按 Ctrl+C 可以终止下载)')
println('')

// 执行命令
exit_code := os.system(cmd_str)

println('')
match exit_code {
	0 {
		println('🎉 下载完成！')
	}
	130, 2 {
		println('⏹️  下载已取消')
		exit(1)
	}
	else {
		println('❌ 下载失败，错误码: $exit_code')
		println('')
		println('可能的解决方案:')
		println('1. 检查URL是否正确')
		println('2. 确保Edge浏览器已登录YouTube账户（如果需要）')
		println('3. 尝试更新yt-dlp: pip install --upgrade yt-dlp')
		println('4. 检查网络连接')
		println('5. 尝试添加 --user_agent 参数')
		println('6. 尝试使用其他浏览器cookies: --cookies-from-browser chrome')
		exit(1)
	}
}