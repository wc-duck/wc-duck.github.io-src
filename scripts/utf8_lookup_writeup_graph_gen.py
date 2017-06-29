import os
import sys

lines_per_test = 9
file_to_testres = {}

def find_test_files(lines):
    files = []
    for l in lines:
        if l.startswith('test text: test/texts/'):
            files.append(l[len('test text: test/texts/'):].strip())
    return files

def find_test_types(lines):
    types = []
    test_lines = lines[0:lines_per_test]
    for l in test_lines[3:]:
        items = l.split()
        types.append(items[0])
    return types

def write_bar_data(f, types, files, item):
    f.write(',%s\n' % ','.join(types))
    for test_file in files:
        line = [test_file]
        for test_type in types:
            line.append(str(file_to_testres[test_file][test_type][item]))
        f.write('%s\n' % ','.join(line))

def write_scatter_data(f, types, files, item1, item2):
    for test_file in files:
        f.write('%s\n' % test_file)
        for test_type in types:
            f.write('%s,%f,%f\n' % ( test_type, file_to_testres[test_file][test_type][item1], file_to_testres[test_file][test_type][item2]))

def main():
    input_file = sys.argv[1]

    with open( input_file, 'rb') as f:
        lines = f.readlines()
        test_files = find_test_files(lines)
        test_types = find_test_types(lines)

        for file in test_files:
            d = {}
            for type in test_types:
                d[type] = {}
            file_to_testres[file] = d
 
        for i in range(len(lines)):
            l = lines[i]
            if l.startswith('test text: test/texts/'):
                test_file = l[len('test text: test/texts/'):].strip()
                for test in range(len(test_types)):
                    items = lines[i+test+2].split()
                    test_type = items[0]
                    file_to_testres[test_file][test_type]['memuse'] = float(items[3])
                    file_to_testres[test_file][test_type]['byte_per_cp'] = float(items[4])
                    file_to_testres[test_file][test_type]['cp_per_us'] = float(items[5])
                    file_to_testres[test_file][test_type]['gb_sec'] = float(items[6])

    test_types_no_std = [t for t in test_types if not t.startswith('std::')]

    bar_charts     = [ ( 'memuse_all.csv',          'Memory use' ), 
                       ( 'memuse_no_std.csv',       'Memory use' ), 
                       ( 'gb_per_sec.csv',          'GB/sec' ), 
                       ( 'gb_per_sec_no_std.csv',   'GB/sec' ), 
                       ( 'bytes_per_cp.csv',        'Bytes/Codepoint' ),
                       ( 'bytes_per_cp_no_std.csv', 'Bytes/Codepoint' )]
    scatter_charts = [ ( 'bpcp_vs_cppus.csv',       'Bytes/Codepoint vs 10000 Codepoints/us'),
                       ('bpcp_vs_cppus_no_std.csv', 'Bytes/Codepoint vs 10000 Codepoints/us' )]

    chart_dir = 'local/%s_charts' % os.path.splitext(os.path.split(input_file)[1])[0]
    if not os.path.isdir(chart_dir):
        os.makedirs(chart_dir)

    with open( os.path.join(chart_dir, 'memuse_all.csv'),          'wb' ) as f: write_bar_data(f, test_types,        test_files, 'memuse')
    with open( os.path.join(chart_dir, 'memuse_no_std.csv'),       'wb' ) as f: write_bar_data(f, test_types_no_std, test_files, 'memuse')
    with open( os.path.join(chart_dir, 'gb_per_sec.csv'),          'wb' ) as f: write_bar_data(f, test_types,        test_files, 'gb_sec')
    with open( os.path.join(chart_dir, 'gb_per_sec_no_std.csv'),   'wb' ) as f: write_bar_data(f, test_types_no_std, test_files, 'gb_sec')
    with open( os.path.join(chart_dir, 'bytes_per_cp.csv'),        'wb' ) as f: write_bar_data(f, test_types,        test_files, 'byte_per_cp')
    with open( os.path.join(chart_dir, 'bytes_per_cp_no_std.csv'), 'wb' ) as f: write_bar_data(f, test_types_no_std, test_files, 'byte_per_cp')
    
    with open( os.path.join(chart_dir, 'bpcp_vs_cppus.csv'),        'wb' ) as f: write_scatter_data(f, test_types,        test_files, 'byte_per_cp', 'cp_per_us')
    with open( os.path.join(chart_dir, 'bpcp_vs_cppus_no_std.csv'), 'wb' ) as f: write_scatter_data(f, test_types_no_std, test_files, 'byte_per_cp', 'cp_per_us')
    
    wccharts = '../wcchart/build/wcchart'
    
    for c, title in bar_charts:
        os.system("cat " + os.path.join(chart_dir, c)+ " | " + wccharts + " --type bar --title=\"" + title + "\" --output " + os.path.join(chart_dir, c).replace('.csv', '.png'))
        
    for c, title in scatter_charts:
        os.system("cat " + os.path.join(chart_dir, c)+ " | " + wccharts + " --type scatter --title=\"" + title + "\" --output " + os.path.join(chart_dir, c).replace('.csv', '.png'))
    

if __name__ == "__main__":
    main()