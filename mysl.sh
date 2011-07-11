#!/usr/bin/env bash

# mysl.sh
# Copyright (c) 2011 TAKEI Yuya
# http://d.hatena.ne.jp/goth_wrist_cut/

fetchs="";

fetchs="${fetchs} wget";
function fetch_wget()
{
	local url="${1}";
	local output="${2}";
	wget -O"${output}" "${url}";
}

fetchs="${fetchs} fetch";
function fetch_fetch()
{
	local url="${1}";
	local output="${2}";
	fetch -o"${output}" "${url}";
}

fetchs="${fetchs} curl";
function fetch_curl()
{
	local url="${1}";
	local output="${2}";
	curl -f -o"${output}" "${url}";
}

fetchs="${fetchs} dog";
function fetch_dog()
{
	local url="${1}";
	local output="${2}";
	dog "${url}" > "${output}";
}

fetchs="${fetchs} ruby"
function fetch_ruby()
{
	local url="${1}";
	local output="${2}";
	local prot="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\1#p;d'`";
	local host="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\2#p;d'`";
	local port="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\4#p;d'`";
	local path="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\5#p;d'`";
	if [ -z "${host}" ]; then return 1; fi
	ruby -r "net/http" -e "Net::HTTP.start('${host}',${port:=80}){|http| res = http.get('${path}'); if res.code == '200' then File.open('${output}','w'){|f| f.write res.body } else puts res.code; exit 1 end }"
}

fetchs="${fetchs} nc";
function fetch_nc()
{
	local url="${1}";
	local output="${2}";
	local output_tmp="${output}.tmp";
	local prot="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\1#p;d'`";
	local host="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\2#p;d'`";
	local port="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\4#p;d'`";
	local path="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\5#p;d'`";
	if [ -z "${host}" ]; then return 1; fi
	(
	echo "GET ${url} HTTP/1.0\r\n";
	echo "Host: ${host}\r\n";
	echo "\r\n";
	) | nc "${host}" "${port:=80}" > "${output_tmp}";
	status="`sed -n '1,/^\s*$/s#\(HTTP/[0-9.]*\) \([0-9]*\) \(.*\)#\2#p' "${output_tmp}"`";
	print_log "iSTAUTS ${status}\n";
	if [ "${status}0" -ne 2000 ]; then
		echo "Return Code: ${status}";
		rm -f "${output_tmp}";
		return 1;
	fi
	sed -e '1,/^\s*$/d' "${output_tmp}" > "${output}";
	rm -f "${output_tmp}"
}

fetchs="${fetchs} telnet"
function fetch_telnet()
{
	local url="${1}";
	local output="${2}";
	local output_tmp="${output}.tmp";
	local prot="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\1#p;d'`";
	local host="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\2#p;d'`";
	local port="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\4#p;d'`";
	local path="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\5#p;d'`";
	if [ -z "${host}" ]; then return 1; fi
	(
	sleep 1; echo "GET ${url} HTTP/1.0";
	sleep 1; echo "Host: ${host}";
	sleep 1; echo "";
	sleep 2;
	) | telnet "${host}" "${port:=80}" > "${output_tmp}";
	status="`sed -n '1,/^\s*$/s#\(HTTP/[0-9.]*\) \([0-9]*\) \(.*\)#\2#p' "${output_tmp}"`";
	if [ "${status}0" -ne 2000 ]; then
		echo "Return Code: ${status}";
		rm -f "${output_tmp}";
		return 1;
	fi
	sed -e '1,/^\s*$/d' "${output_tmp}" > "${output}";
	rm -f "${output_tmp}"
}

fetchs="${fetchs} error"
function fetch_error()
{
	echo "There are no way to fetch remote file.";
	exit 1;
}

function get_remote_file()
{
	local output="${1}";
	shift
	for fetch in ${fetchs}; do
		for url in $@; do
			printf "Using ${fetch} to fetch ${url}\n";
			if fetch_${fetch} "${url}" "${output}"; then
				if [ -s "${output}" ]; then
					fetchs="${fetch} error";
					return 0;
				fi
			fi
		done
	done
	return 1;
}

# settings
install_dir="`mktemp -d ${HOME}/.sl-tmp.XXXXXXXX`";
cd "${install_dir}";

bin_dir="${install_dir}/bin" && mkdir -p "${bin_dir}";
lib_dir="${install_dir}/lib" && mkdir -p "${lib_dir}";
include_dir="${install_dir}/include" && mkdir -p "${include_dir}";

log_file="${install_dir}/log";

ncurses_urls="
http://www.coins.tsukuba.ac.jp/~i0611238/ncurses-5.9.tar.gz
http://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.9.tar.gz
";
sl_urls="
http://www.coins.tsukuba.ac.jp/~i0611238/sl.tar
http://www.tkl.iis.u-tokyo.ac.jp/~toyoda/sl/sl.tar
";
patch_urls="
http://www.coins.tsukuba.ac.jp/~i0611238/sl5-1.patch
http://www.izumix.org.uk/sl/sl5-1.patch
";

ncurses_dir="${install_dir}/ncurses-5.9";
sl_dir="${install_dir}/sl";

ncurses_file="${install_dir}/ncurses.tar.gz";
sl_file="${install_dir}/sl.tar";
patch_file="${sl_dir}/sl5-1.patch";

bash_aliases="${install_dir}/bash_aliases"
zsh_aliases="${install_dir}/zsh_aliases"
csh_aliases="${install_dir}/csh_aliases"

bashrc="${HOME}/.bashrc"
zshrc="${HOME}/.zshrc"
cshrc="${HOME}/.cshrc"

bashrc_backup="${install_dir}/bashrc_backup";
zshrc_backup="${install_dir}/zshrc_backup";
cshrc_backup="${install_dir}/cshrc_backup";

function print_log()
{
	printf "$@";
	printf "$@" >> "${log_file}";
}

function die()
{
	print_log "die: install failed\n";
	if [ -f "${bashrc_backup}" ]; then
		mv -f "${bashrc_backup}" "${bashrc}"
	fi
	if [ -f "${zshrc_backup}" ]; then
		mv -f "${zshrc_backup}" "${zshrc}"
	fi
	if [ -f "${cshrc_backup}" ]; then
		mv -f "${cshrc_backup}" "${cshrc}"
	fi
	# rm -fr "${install_dir}";
	exit 1;
}

function has()
{
	which $@ >/dev/null
}

print_log "Install directory: ${install_dir}\n";
export C_INCLUDE_PATH="${include_dir}:${C_INCLUDE_PATH}";
export LIBRARY_PATH="${lib_dir}:${LIBRARY_PATH}";
export PATH="${bin_dir}:${PATH}";

# check if ncurses is installed
ncurses_tmp="${install_dir}/tmp";
sl_CFLAGS=""

print_log "Checking for ncurses ... ";
if [ -z "${sl_CFLAGS}" ]; then
	cat <<-'HERE' | gcc -o ${ncurses_tmp} -lncurses -x c -
#include <curses.h>

int main()
{
	initscr();
	endwin();
	return 0;
}
	HERE
	if [ -e "${ncurses_tmp}" ]; then
		sl_CFLAGS="-Wall -O2"
		print_log "YES\n"
	fi
fi

if [ -z "${sl_CFLAGS}" ]; then
	cat <<-'HERE' | gcc -o ${ncurses_tmp} -lncurses -x c -
#include <ncurses/curses.h>

int main()
{
	initscr();
	endwin();
	return 0;
}
	HERE
	if [ -e "${ncurses_tmp}" ]; then
		sl_CFLAGS="-Wall -O2 -DLINUX20"
		print_log "YES(LINUX20)\n";
	fi
fi

if [ -z "${sl_CFLAGS}" ]; then
	print_log "NO\n";

	print_log "Fetching ncurses ... ";
	# fetch ncurses
	get_remote_file "${ncurses_file}" "${ncurses_urls}" >>"${log_file}" 2>&1 || die;
	tar -xzf "${ncurses_file}" -C "${install_dir}" || die;
	print_log "DONE\n";

	print_log "Making ncurses ... ";
	# make and install ncurses
	./configure --prefix="${install_dir}" >>"${log_file}" 2>&1 || die;
	make -C "${ncurses_dir}" >>"${log_file}" 2>&1 || die;
	make -C "${ncurses_dir}" install >>"${log_file}" 2>&1 || die;
	print_log "DONE\n";
fi

# fetch sl
print_log "Fetching sl ... ";
(
get_remote_file "${sl_file}" "${sl_urls}" &&
tar -xf "${sl_file}" -C "${install_dir}"
) >> "${log_file}" 2>&1 || die;
print_log "DONE\n";

# fetch patch
print_log "Fetching patch ... ";
get_remote_file "${patch_file}" "${patch_urls}" >>"${log_file}" 2>&1 || die;
print_log "DONE\n";

# patch and make, install
print_log "Applying patch ... ";
patch -d "${sl_dir}" -f < "${patch_file}" >>"${log_file}" 2>&1 || die;
print_log "DONE\n";

print_log "Making SL ... ";
CFLAGS="${ncurses_CFLAGS}" make -C "${sl_dir}" -e >>"${log_file}" 2>&1 || die;
cp "${sl_dir}/sl" "${bin_dir}" || die;
print_log "DONE\n";

# make aliases
print_log "Gathering alias information ... ";
echo "export PATH=${bin_dir}" > "${bash_aliases}" || die;
echo "setenv PATH ${bin_dir}" > "${csh_aliases}" || die;
echo "export PATH=${bin_dir}" > "${zsh_aliases}" || die;
if has sed; then
	PATHs="`echo ${PATH} | sed "s/:/ /g"`";
elif has tr; then
	PATHs="`echo ${PATH} | tr ":" " "`";
else
	oldIFS="${IFS}";
	IFS=":";
	PATHs=""
	for p in ${PATH}; do
		PATHs="${PATHs} ${p}";
	done
	IFS="${oldIFS}";
fi
aliases_path="`find ${PATHs} -maxdepth 1 -type f ! -iname alias -exec basename {} \;`";
if has sed; then
	aliases_bash="`bash -c "source ${bashrc}; alias" | sed -e "s/^alias \([^=]*\).*$/\1/"`";
elif has cut; then
	aliases_bash="`bash -c "source ${bashrc}; alias" | cut -d"=" -f1 | cut -d" " -f2`";
fi
if has sed; then
	aliases_csh="`csh -c "source ${cshrc}; alias" | sed -e "s/^\(\S*\).*$/\1/"`";
elif has cut; then
	aliases_csh="`csh -c "source ${cshrc}; alias" | cut -f1`";
fi
if has sed; then
	aliases_zsh="`zsh -c "source ${zshrc}; alias" | sed -e "s/^\([^=]*\).*$/\1/"`";
elif has cut; then
	aliases_zsh="`zsh -c "source ${zshrc}; alias" | cut -d"=" -f1`";
fi
aliases="${aliases_path} ${aliases_bash} ${aliases_csh} ${aliases_zsh} exit logout unalias alias";
print_log "DONE\n";

print_log "Dumping aliases ... ";
for i in ${aliases}; do
	# alias of "alias" must be last
	echo "\\\\alias '${i}'='sl'" >> "${bash_aliases}" || die;
	echo "\\\\alias '${i}'='sl'" >> "${zsh_aliases}" || die;
	echo "alias '${i}' 'sl'" >> "${csh_aliases}" || die;
done
print_log "DONE\n";

# make backup and inject sl
print_log "Installing MySL ... ";
if [ -f "${bashrc}" ]; then
	cp "${bashrc}" "${bashrc_backup}" || die;
	(
	echo "test -f ${bash_aliases} && source ${bash_aliases} && return";
	cat "${bashrc_backup}";
	) >> "${bashrc}"
fi

if [ -f "${zshrc}" ]; then
	cp "${zshrc}" "${zshrc_backup}" || die;
	(
	echo "test -f ${zsh_aliases} && source ${zsh_aliases} && return";
	cat "${zshrc_backup}";
	) >> "${zshrc}"
fi

if [ -f "${cshrc}" ]; then
	cp "${cshrc}" "${cshrc_backup}" || die;
	(
	echo "test -f ${csh_aliases} && source ${csh_aliases} && return";
	cat "${cshrc_backup}";
	) >> "${cshrc}"
fi
print_log "DONE\n";

print_log "\n";
print_log "MySL installation success!!\n";
print_log "Enjoy your SL life!\n";
print_log "\n";
print_log "To uninstall mysl:\n";
print_log " Delete first line of RC file: ~/.bashrc,  ~/cshrc or/and ~/zshrc\n";
print_log " Remove directory '${install_dir}': rm -rf ${install_dir}\n";
