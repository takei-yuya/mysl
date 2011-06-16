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
	curl "${url}" > "${output}";
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
	ruby -r "net/http" -e "File.open('${output}','w'){|f| f.write(Net::HTTP.get('${host}', '${path}', ${port:=80})) }"
}

fetchs="${fetchs} nc";
function fetch_nc()
{
	local url="${1}";
	local output="${2}";
	local prot="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\1#p;d'`";
	local host="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\2#p;d'`";
	local port="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\4#p;d'`";
	local path="`echo "${url}" | sed 's#\(http\)://\([^/:]*\)\(:\([0-9]*\)\)\{0,1\}\(/.*\)#\5#p;d'`";
	if [ -z "${host}" ]; then return 1; fi
	(
	echo "GET ${url} HTTP/1.0\r\n";
	echo "Host: ${host}\r\n";
	echo "\r\n";
	) \
		| nc "${host}" "${port:=80}" \
		| sed '1,/^\s*$/d' > ${output};
}

fetchs="${fetchs} telnet"
function fetch_telnet()
{
	local url="${1}";
	local output="${2}";
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
	) \
		| telnet "${host}" "${port:=80}" \
		| sed '1,/^\s*$/d' > ${output};
}

fetchs="${fetchs} error"
function fetch_error()
{
	echo "There are no way to fetch remote file.";
	exit 1;
}

function get_remote_file()
{
	local url="${1}";
	local output="${2}";
	for fetch in ${fetchs}; do
		if fetch_${fetch} "${url}" "${output}"; then
			fetchs="${fetch} error";
			return 0;
		fi
	done
	return 1;
}

# settings
install_dir="`mktemp -d ${HOME}/.sl-tmp.XXXXXXXX`";
bin_dir="${install_dir}/bin";
lib_dir="${install_dir}/lib";
include_dir="${install_dir}/include";

ncurses_url="http://ftp.gnu.org/pub/gnu/ncurses/ncurses-5.9.tar.gz";
sl_url="http://www.tkl.iis.u-tokyo.ac.jp/~toyoda/sl/sl.tar";
patch_url="http://www.izumix.org.uk/sl/sl5-1.patch";

ncurses_file="`basename "${ncurses_url}"`";
sl_file="`basename "${sl_url}"`";
patch_file="`basename "${patch_url}"`";

ncurses_dir="${install_dir}/ncurses-5.9";
sl_dir="${install_dir}/sl";

bash_aliases="${install_dir}/bash_aliases"
zsh_aliases="${install_dir}/zsh_aliases"
csh_aliases="${install_dir}/csh_aliases"

bashrc="${HOME}/.bashrc"
zshrc="${HOME}/.zshrc"
cshrc="${HOME}/.cshrc"

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

# fetch ncurses
cd "${install_dir}" || die;
get_remote_file "${ncurses_url}" "${ncurses_file}" || die;
tar -xzf "${ncurses_file}" || die;

# make and install ncurses
cd "${ncurses_dir}" || die;
./configure --prefix="${install_dir}" || die;
make || die;
make install || die;

# fetch sl
cd "${install_dir}" || die;
get_remote_file "${sl_url}" "${sl_file}" || die;
tar -xf "${sl_file}" || die;

# patch and make, install
cd "${sl_dir}" || die;
get_remote_file "${patch_url}" "${patch_file}" || die;
patch -f < "${patch_file}" || die;
make || die;
cp "${sl_dir}/sl" "${bin_dir}" || die;

# make aliases
cd "${install_dir}";
echo "export PATH=${bin_dir}" > "${bash_aliases}" || die;
echo "export PATH=${bin_dir}" > "${zsh_aliases}" || die;
echo "export PATH=${bin_dir}" > "${csh_aliases}" || die;
PATHs="`echo ${PATH} | sed "s/:/ /g"`";
for i in `find ${PATHs} -maxdepth 1 -type f ! -iname alias` exit logout unalias alias; do
	# alias of alias must be last
	echo "\\\\alias '$(basename ${i})'='sl'" >> "${bash_aliases}" || die;
	echo "\\\\alias '$(basename ${i})'='sl'" >> "${zsh_aliases}" || die;
	echo "alias '$(basename ${i})' 'sl'" >> "${csh_aliases}" || die;
done

# make backup and inject sl
if [ -f "${bashrc}" ]; then
	cp "${bashrc}" "${install_dir}" || die;
	sed -i"" -e "1i\\
test -f ${bash_aliases} && source ${bash_aliases} && return\\
" "${bashrc}" || die;
fi

if [ -f "${zshrc}" ]; then
	cp "${zshrc}" "${install_dir}" || die;
	sed -i"" -e "1i\\
test -f ${zsh_aliases} && source ${zsh_aliases} && return\\
" "${zshrc}" || die;
fi

if [ -f "${cshrc}" ]; then
	cp "${cshrc}" "${install_dir}" || die;
	sed -i"" -e "1i\\
test -f ${csh_aliases} && source ${csh_aliases} && return\\
" "${cshrc}" || die;
fi

echo "install done: ${install_dir}";
