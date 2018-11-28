import requests
import logging
import math
from datetime import datetime

try:
    import http.client as http_client
except ImportError:
    # Python 2
    import httplib as http_client
http_client.HTTPConnection.debuglevel = 1

logging.basicConfig()
logging.getLogger().setLevel(logging.DEBUG)
requests_log = logging.getLogger("requests.packages.urllib3")
requests_log.setLevel(logging.DEBUG)
requests_log.propagate = True

SERVERS = [
    'zdyh3amosc01',
    'zdyh3amosc02',
    'zdyh3amosc03',
]

date_ranges = [
    [datetime(2018, 9, 17, 19, 0), datetime(2018, 9, 17, 19, 59)],
    [datetime(2018, 9, 17, 20, 0), datetime(2018, 9, 17, 20, 59)],
]

date_ranges = [
    [datetime(2018, 4, 28, 3, 0), datetime(2018, 4, 29, 2, 59)],
    [datetime(2018, 5, 1, 15, 0), datetime(2018, 5, 2, 14, 59)]
]

LA_METRIC_QUERIES = [
    ('mean', "SELECT mean(value) FROM load_longterm WHERE {filt}"),
    ('90%ile', "SELECT percentile(value, 90) FROM load_longterm WHERE {filt}"),
    ('95%ile', "SELECT percentile(value, 95) FROM load_longterm WHERE {filt}"),
    ('stddev', "SELECT stddev(value) FROM load_longterm WHERE {filt}"),
]

SYSCALL_METRIC_QUERIES = [
    ('mean', "SELECT mean(value) FROM sys_cpu_per_core_1s WHERE {filt}"),
    ('90%ile', "SELECT percentile(value, 90) FROM sys_cpu_per_core_1s WHERE {filt}"),
    ('95%ile', "SELECT percentile(value, 95) FROM sys_cpu_per_core_1s WHERE {filt}"),
    ('99%ile', "SELECT percentile(value, 99) FROM sys_cpu_per_core_1s WHERE {filt}"),
    ('stddev', "SELECT stddev(value) FROM sys_cpu_per_core_1s WHERE {filt}"),
]

CPUS_METRIC_QUERIES = [
    ('mean', "SELECT mean(value) FROM cpu_user WHERE {filt}"),
    ('95%ile', "SELECT percentile(value, 95) FROM cpu_user WHERE {filt}"),

    ('mean', "SELECT mean(value) FROM cpu_system WHERE {filt}"),
    ('95%ile', "SELECT percentile(value, 95) FROM cpu_system WHERE {filt}"),

    ('mean', "SELECT mean(value) FROM cpu_wait WHERE {filt}"),
    ('95%ile', "SELECT percentile(value, 95) FROM cpu_wait WHERE {filt}"),

]


CPU_TOTAL_METRIC_QUERIES = [
    ('mean', "SELECT mean(value) FROM cpu_user WHERE {filt}"),
    ('mean', "SELECT mean(value) FROM cpu_system WHERE {filt}"),

    ('95%ile', "SELECT percentile(value, 95) FROM cpu_user WHERE {filt}"),
    ('95%ile', "SELECT percentile(value, 95) FROM cpu_system WHERE {filt}"),
]


def calc_diff(old, new):
    if not old:
        return 0
    return ((new - old) / old) * 100


def statistics(server, period, query):
    if period[1] != '':
        filt = "hostname =~ /{server}/ AND time >= '{tfrom}' AND time < '{tto}'".format(server=server, tfrom=period[0], tto=period[1])
    else:
        filt = "hostname =~ /{server}/ AND time >= now() - 30m AND time < now()".format(server=server)
    params = {
        'q': query.format(filt=filt)
    }
    r = requests.get('http://32.68.72.253:8086/query?db=grafana', params=params)
    resp_json = r.json()

    data = []
    for result in resp_json['results']:
        for metrics in result['series']:
            for metric in metrics['values']:
                datetime, value = metric
                data.append(value)

    return data[0]

def get_fresh_metrics(servers, metric_queries):
    stats = {}
    for server in servers:
        stats[server] = []
        for name, q in metric_queries:
            calculated = []
            calculated.append(statistics(server, ['', ''], q))

            stats[server].append(calculated)

    return stats


def get_metrics(servers, metric_queries):
    stats = {}
    for server in servers:
        stats[server] = []
        for name, q in metric_queries:
            calculated = []
            for period in date_ranges:
                calculated.append(statistics(server, period, q))

            stats[server].append(calculated + [calc_diff(*calculated)])

    return stats


def get_sum_metrics(servers, metric_queries):
    stats = {}
    for server in servers:
        stats[server] = []
        for period in date_ranges:
            calculated = {}
            for name, q in metric_queries:
                calculated.setdefault(name, 0)
                calculated[name] += statistics(server, period, q)
            stats[server].append(calculated)

    for server, metrics in stats.items():
        stats[server] = []
        for key in ['mean', '95%ile']:
            values = [i[key] for i in metrics]
            values += [calc_diff(*values)]
            stats[server].extend([values])

    return stats


def print_fresh_metrics(stats):
    for server, data in sorted(stats.items()):
        line = server + ' '
        for metrics in data:
            line += ' '.join([str(int(i)) for i in metrics[:2]])
            line += ' '
        print(line)


def print_metrics(stats):
    for server, data in sorted(stats.items()):
        line = server + ' '
        for metrics in data:
            # line += ' '.join([str(round(i, 2)) for i in metrics[:2]])
            line += ' '.join([str(int(i)) for i in metrics[:2]])
            line += ' '
            line += str(int(metrics[2])) + '%'
            line += ' '
        print(line)


# print_metrics(get_metrics(SERVERS, LA_METRIC_QUERIES))
# print_metrics(get_metrics(SERVERS, CPUS_METRIC_QUERIES))
# print_metrics(get_sum_metrics(SERVERS, CPU_TOTAL_METRIC_QUERIES))
#print_metrics(get_metrics(SERVERS, SYSCALL_METRIC_QUERIES))
print_fresh_metrics(get_fresh_metrics(SERVERS, CPUS_METRIC_QUERIES))
