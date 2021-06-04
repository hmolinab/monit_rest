# monit_rest
The M/Monit status output in JSON.

## M/Monit to rest
Do you need to read the M/Monit status remotely? monit_rest.rb exposes the "monit status" output in JSON format, it only needs a ruby installation and the monit's HTTP interface enabled.

## Outputs

| URI | Output |
|-----|--------|
| /Monit | JSON |
| /Monit/pp | Pretty print JSON |
| /Monit/raw | Raw monit status output |

## Install
```
$ sudo cp monit_rest.rb /usr/local/bin
$ sudo chmod +x /usr/local/bin/monit_rest.rb
$ [ -f /etc/debian_version ] && sudo cp monit_rest /etc/monit/conf-enabled/monit_rest
$ [ -f /etc/redhat-release ] && sudo cp monit_rest /etc/monit.d/monit_rest
$ sudo monit reload monit_rest
$ sudo monit status monit_rest
```
Monit will keep alive monit_rest.rb application.

## Testing
```
$ sudo monit status
$ curl http://localhost:2813/Monit/raw
$ curl http://localhost:2813/Monit/pp
$ curl http://localhost:2813/Monit
```

