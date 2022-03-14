kernver=5.16.4
kernurl="https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.16.4.tar.xz"

pkgver=${kernver//./}
pkgrel=1
pkgdesc='Linux Kernel'
url="http://www.kernel.org/"
arch=(x86_64)
license=(GPL2)
makedepends=(
  bc kmod libelf pahole cpio perl tar xz zstd
)
provides=(linux)

pkgbase=linux"$pkgver"
pkgname=("${pkgbase}" "${pkgbase}"-headers)
for _p in "${pkgname[@]}"; do
  eval "package_$_p() {
    $(declare -f "_package${_p#"$pkgbase"}")
    _package${_p#"$pkgbase"}
  }"
done

build() {
  cd "$startdir"/linux
  echo -n "${kernver}" > version
  cat <<EOF > "$pkgbase".preset
# mkinitcpio preset file for the '$pkgver' package

ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-$kernver-x86_64"

PRESETS=('default')

default_config="/etc/mkinitcpio.conf"
default_image="/boot/initramfs-$kernver-x86_64.img"
default_options=""
EOF
  msg2 "Building the Linux kernel..."
  make LLVM=1 -j$(($(nproc)+1))
}

_package() {
  cd "$startdir"
  mkdir -p linux
  cd linux
  mkdir "$pkgdir/boot"
  local kernver="$kernver"
  install -Dm644 "$(make -s image_name)" "$pkgdir/boot/vmlinuz-$kernver-x86_64"
  mkdir -p "$pkgdir/etc/mkinitcpio.d/"
  cp "$pkgbase".preset "$pkgdir/etc/mkinitcpio.d/"
  make INSTALL_MOD_PATH="$pkgdir/usr" INSTALL_MOD_STRIP=1 LLVM=1 modules_install -j$(($(nproc)+1))
  rm "$pkgdir/usr/lib/modules/${kernver}/build" -r
}


_package-headers() {
  pkgdesc="Headers and scripts for building modules for the $pkgdesc kernel"
  depends=(pahole)

  cd "$startdir"/linux
  mkdir -p "$pkgdir/usr/lib/modules/$kernver/build"
  local builddir="$pkgdir/usr/lib/modules/$kernver/build"

  msg2 "Installing build files..."
  install -Dt "$builddir" -m644 .config Makefile Module.symvers System.map \
    version vmlinux
  install -Dt "$builddir/kernel" -m644 kernel/Makefile
  install -Dt "$builddir/arch/x86" -m644 arch/x86/Makefile
  cp -t "$builddir" -a scripts

  # required when STACK_VALIDATION is enabled
  install -Dt "$builddir/tools/objtool" tools/objtool/objtool

  # required when DEBUG_INFO_BTF_MODULES is enabled
  if [ -f "$builddir/tools/bpf/resolve_btfids" ]; then install -Dt "$builddir/tools/bpf/resolve_btfids" tools/bpf/resolve_btfids/resolve_btfids ; fi

  msg2 "Installing headers..."
  cp -t "$builddir" -a include
  cp -t "$builddir/arch/x86" -a arch/x86/include
  install -Dt "$builddir/arch/x86/kernel" -m644 arch/x86/kernel/asm-offsets.s

  install -Dt "$builddir/drivers/md" -m644 drivers/md/*.h
  install -Dt "$builddir/net/mac80211" -m644 net/mac80211/*.h

  # https://bugs.archlinux.org/task/13146
  install -Dt "$builddir/drivers/media/i2c" -m644 drivers/media/i2c/msp3400-driver.h

  # https://bugs.archlinux.org/task/20402
  install -Dt "$builddir/drivers/media/usb/dvb-usb" -m644 drivers/media/usb/dvb-usb/*.h
  install -Dt "$builddir/drivers/media/dvb-frontends" -m644 drivers/media/dvb-frontends/*.h
  install -Dt "$builddir/drivers/media/tuners" -m644 drivers/media/tuners/*.h

  # https://bugs.archlinux.org/task/71392
  install -Dt "$builddir/drivers/iio/common/hid-sensors" -m644 drivers/iio/common/hid-sensors/*.h

  echo "Installing KConfig files..."
  find . -name 'Kconfig*' -exec install -Dm644 {} "$builddir/{}" \;

  msg2 "Removing unneeded architectures..."
  local arch
  for arch in "$builddir"/arch/*/; do
    [[ $arch = */x86/ ]] && continue
    echo "Removing $(basename "$arch")"
    rm -r "$arch"
  done

  msg2 "Removing documentation..."
  rm -r "$builddir/Documentation"

  msg2 "Removing broken symlinks..."
  find -L "$builddir" -type l -printf 'Removing %P\n' -delete

  msg2 "Removing loose objects..."
  find "$builddir" -type f -name '*.o' -printf 'Removing %P\n' -delete

  msg2 "Stripping build tools..."
  local file
  while read -rd '' file; do
    case "$(file -bi "$file")" in
      application/x-sharedlib\;*)      # Libraries (.so)
        strip -v $STRIP_SHARED "$file" ;;
      application/x-archive\;*)        # Libraries (.a)
        strip -v $STRIP_STATIC "$file" ;;
      application/x-executable\;*)     # Binaries
        strip -v $STRIP_BINARIES "$file" ;;
      application/x-pie-executable\;*) # Relocatable binaries
        strip -v $STRIP_SHARED "$file" ;;
    esac
  done < <(find "$builddir" -type f -perm -u+x ! -name vmlinux -print0)

  msg2 "Stripping vmlinux..."
  strip -v $STRIP_STATIC "$builddir/vmlinux"
  
  msg2 "Adding symlink..."
  mkdir -p "$pkgdir/usr/src"
  ln -sr "$builddir" "$pkgdir/usr/src/$pkgbase"

  msg2 "Install module signing key..."
  install -Dt "$builddir/certs/" -m600 certs/signing_key.pem certs/signing_key.x509

}
