from optparse import OptionParser
import hpilo
import ssl


def parse_options():
    parser = OptionParser()

    parser.add_option(
        '--username',
        dest='username',
        default=False,
        help='username used to login into ilo'
    )

    parser.add_option(
        '--password',
        dest='password',
        default=False,
        help='password used to login into ilo'
    )

    parser.add_option(
        '--host',
        dest='host',
        default=False,
        help='host which to boot to iso'
    )

    parser.add_option(
        '--iso-host',
        dest='iso_host',
        default=False,
        help='host which has the iso'
    )

    parser.add_option(
        '--iso-name',
        dest='iso_name',
        default=False,
        help='name of the iso file'
    )

    return parser.parse_args()[0]


def boot_to_iso(options):
    """Boots the given hp proliant server to the given iso."""
    ilo = hpilo.Ilo(options.host, login=options.username, password=options.password, timeout=6000, ssl_context=ssl.SSLContext(ssl.PROTOCOL_TLSv1_1))
    ilo.ssl_context.set_ciphers('ALL:@SECLEVEL=0')
    ilo.insert_virtual_media('cdrom', f'{options.iso_host}/{options.iso_name}')
    ilo.set_vm_status(device='cdrom', boot_option='boot_once', write_protect=True)
    ilo.set_one_time_boot('cdrom')
    ilo.reset_server()


def main():
    options = parse_options()
    boot_to_iso(options)


if __name__ == '__main__':
    main()
