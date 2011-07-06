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
	if [ "${status}" -ne 200 ]; then
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
	if [ "${status}" -ne 200 ]; then
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
			echo "Using ${fetch} to fetch ${url}"
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
bin_dir="${install_dir}/bin" && mkdir -p "${bin_dir}";
lib_dir="${install_dir}/lib" && mkdir -p "${lib_dir}";
include_dir="${install_dir}/include" && mkdir -p "${include_dir}";

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

ncurses_file="ncurses.tar.gz";
sl_file="sl.tar";
patch_file="sl5-1.patch";

ncurses_dir="${install_dir}/ncurses-5.9";
sl_dir="${install_dir}/sl";

bash_aliases="${install_dir}/bash_aliases"
zsh_aliases="${install_dir}/zsh_aliases"
csh_aliases="${install_dir}/csh_aliases"

bashrc="${HOME}/.bashrc"
zshrc="${HOME}/.zshrc"
cshrc="${HOME}/.cshrc"

bashrc_backup="${install_dir}/bashrc_backup";
zshrc_backup="${install_dir}/zshrc_backup";
cshrc_backup="${install_dir}/cshrc_backup";

function die()
{
	echo "die: install failed";
	rm -fr "${install_dir}";
	exit 1;
}

echo "${install_dir}";
export C_INCLUDE_PATH="${include_dir}:${C_INCLUDE_PATH}";
export LIBRARY_PATH="${lib_dir}:${LIBRARY_PATH}";
export PATH="${bin_dir}:${PATH}";

# check if ncurses is installed
ncurses_tmp="${install_dir}/tmp";
sl_CFLAGS=""

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
	fi
fi

if [ -z "${sl_CFLAGS}" ]; then
	# fetch ncurses
	cd "${install_dir}" || die;
	get_remote_file "${ncurses_file}" "${ncurses_urls}" || die;
	tar -xzf "${ncurses_file}" || die;

	# make and install ncurses
	cd "${ncurses_dir}" || die;
	./configure --prefix="${install_dir}" || die;
	make || die;
	make install || die;
fi

# fetch sl
cd "${install_dir}" || die;
get_remote_file "${sl_file}" "${sl_urls}" || die;
tar -xf "${sl_file}" || die;

# fetch patch
cd "${sl_dir}" || die;
get_remote_file "${patch_file}" "${patch_urls}" || die;

# patch and make, install
patch -f < "${patch_file}" || die;
CFLAGS="${ncurses_CFLAGS}" make -e || die;
cp "${sl_dir}/sl" "${bin_dir}" || die;

# make aliases
cd "${install_dir}";
echo "export PATH=${bin_dir}" > "${bash_aliases}" || die;
echo "export PATH=${bin_dir}" > "${zsh_aliases}" || die;
echo "export PATH=${bin_dir}" > "${csh_aliases}" || die;
PATHs="`echo ${PATH} | sed "s/:/ /g"`";
aliases_path="`find ${PATHs} -maxdepth 1 -type f ! -iname alias -exec basename {} \;`";
aliases_bash="`bash --login -c alias | sed -e "s/^alias \([^=]*\).*$/\1/"`";
aliases_csh="`csh -c alias | sed -e "s/^\([^	]*\).*$/\1/"`";
aliases_zsh="`zsh -c alias | sed -e "s/^\([^=]*\).*$/\1/"`";
aliases="${aliases_path} ${aliases_bash} ${aliases_csh} ${aliases_zsh} exit logout unalias alias";
for i in ${aliases}; do
	# alias of "alias" must be last
	echo "make alias: ${i}";
	echo "\\\\alias '${i}'='sl'" >> "${bash_aliases}" || die;
	echo "\\\\alias '${i}'='sl'" >> "${zsh_aliases}" || die;
	echo "alias '${i}' 'sl'" >> "${csh_aliases}" || die;
done

# make backup and inject sl
if [ -f "${bashrc}" ]; then
	cp "${bashrc}" "${bashrc_backup}" || die;
	sed -e "1i\\
test -f ${bash_aliases} && source ${bash_aliases} && return\\
" "${bashrc_backup}" > "${bashrc}" || die;
fi

if [ -f "${zshrc}" ]; then
	cp "${zshrc}" "${zshrc_backup}" || die;
	sed -e "1i\\
test -f ${zsh_aliases} && source ${zsh_aliases} && return\\
" "${zshrc_backup}" > "${zshrc}" || die;
fi

if [ -f "${cshrc}" ]; then
	cp "${cshrc}" "${cshrc_backup}" || die;
	sed -e "1i\\
test -f ${csh_aliases} && source ${csh_aliases} && return\\
" "${cshrc_backup}" > "${cshrc}" || die;
fi

echo "MySL installation success!!";
echo "Enjoy your SL life!";
echo "";
echo "To uninstall mysl:";
echo " Delete first line of RC file: ~/.bashrc,  ~/cshrc or/and ~/zshrc";
echo " Remove directory '${install_dir}': rm -rf ${install_dir}";
