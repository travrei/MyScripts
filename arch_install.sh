#!/bin/bash

# Script de Instalação do Arch Linux

# Carrega o mapa de teclado ABNT2 (opcional)
loadkeys br-abnt2

# Verifica a conexão com a internet
echo "Verificando a conexão com a internet..."
if ! ping -c 4 google.com > /dev/null; then
  echo "Falha ao conectar à internet. Verifique sua conexão e tente novamente."
  exit 1
fi

echo "Conexão com a internet estabelecida."

# Formatação do SSD
echo "Formatando o SSD..."

# Verifica se o usuário é root
if [ "$EUID" -ne 0 ]; then
  echo "Este script precisa ser executado como root."
  exit 1
fi

# Define o dispositivo NVMe (pode ser necessário ajustar)
NVME="/dev/nvme0n1"

# Verifica se o dispositivo existe
if [ ! -e "$NVME" ]; then
  echo "Dispositivo NVMe não encontrado: $NVME"
  exit 1
fi

# Desmonta todas as partições do NVMe (se houver)
umount "$NVME"* 2>/dev/null

# Apaga a tabela de partição existente
wipefs -a "$NVME"

# Cria a tabela de partição GPT
parted -s "$NVME" mklabel gpt

# Cria as partições (ajuste os tamanhos conforme necessário)
parted -s "$NVME" mkpart ESP fat32 1MiB 512MiB
parted -s "$NVME" set 1 esp on
parted -s "$NVME" mkpart primary linux-swap 512MiB 8.5GiB
parted -s "$NVME" mkpart primary ext4 8.5GiB 100%

# Formata as partições
mkfs.fat -F32 "${NVME}p1"
mkswap "${NVME}p2"
mkfs.ext4 "${NVME}p3"

echo "Partições formatadas com sucesso!"

# Monta as partições
echo "Montando as partições..."
mount "${NVME}p3" /mnt
mkdir -p /mnt/boot/efi
mount "${NVME}p1" /mnt/boot/efi
swapon "${NVME}p2"

# Instala a base do Arch Linux
echo "Instalando o Arch Linux..."
pacstrap /mnt base linux linux-firmware nano vim networkmanager

# Gera o fstab
genfstab -U -p /mnt >> /mnt/etc/fstab

# Configura o sistema no chroot
arch-chroot /mnt

# Configura o fuso horário
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

# Configura a localidade
echo "Configurando a localidade..."
sed -i '/^#.*pt_BR\.UTF-8 UTF-8/s/^#//' /etc/locale.gen
locale-gen

# Define o nome do host
echo "archlinux" > /etc/hostname

# Define a senha de root
echo "drei2110" | passwd

# Cria o usuário (ajuste o nome de usuário e a senha)
useradd -m -g users -G wheel,storage,power -s /bin/bash andreie
echo "drei2110" | passwd andreie

# Instala o GRUB
echo "Instalando o GRUB..."
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=arch_grub --recheck
grub-mkconfig -o /boot/grub/grub.cfg

# Instala o driver de vídeo (opcional, ajuste conforme sua placa de vídeo)
pacman -S xf86-video-amdgpu

echo "Instalação básica concluída! Reinicie e prossiga com a configuração do seu ambiente gráfico."
