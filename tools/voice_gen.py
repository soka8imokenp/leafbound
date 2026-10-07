# Japanese voice for Anzu with a local VOICEVOX engine.
#   .venv/bin/python tools/voice_gen.py list            -> speakers + mean pitch of a test phrase
#   .venv/bin/python tools/voice_gen.py make <style_id> -> voice/<md5(subtitle)>.ogg for tools/voice_lines.json
# Engine: ~/.local/share/voicevox/<folder>/run  (started and stopped by this script)
import hashlib, json, os, subprocess, sys, time, urllib.parse, urllib.request, glob

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
API = 'http://127.0.0.1:50021'
TEST = 'アンズ、おなかすいた！ピーナッツたべたい。'
# Anya-like: high, bright, a bit quick and very expressive
PARAMS = dict(speedScale=1.06, pitchScale=0.04, intonationScale=1.35, volumeScale=1.0,
              prePhonemeLength=0.05, postPhonemeLength=0.18)


def req(path, data=None, method='GET'):
    r = urllib.request.Request(API + path, data=data, method=method,
                               headers={'Content-Type': 'application/json'} if data else {})
    with urllib.request.urlopen(r, timeout=300) as f:
        return f.read()


def start_engine():
    try:
        req('/version'); return None
    except Exception:
        pass
    run = glob.glob(os.path.expanduser('~/.local/share/voicevox/*/run'))[0]
    p = subprocess.Popen([run, '--host', '127.0.0.1', '--port', '50021'], cwd=os.path.dirname(run),
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(120):
        try:
            req('/version'); return p
        except Exception:
            time.sleep(1)
    raise SystemExit('engine did not start')


def query(text, style):
    q = json.loads(req('/audio_query?' + urllib.parse.urlencode({'text': text, 'speaker': style}), b'', 'POST'))
    return q


def mean_pitch(q):
    ps = [m['pitch'] for ap in q['accent_phrases'] for m in ap['moras'] if m['pitch'] > 0]
    return sum(ps) / max(len(ps), 1)


def synth(text, style, out_wav):
    q = query(text, style)
    q.update(PARAMS)
    wav = req('/synthesis?' + urllib.parse.urlencode({'speaker': style}), json.dumps(q).encode(), 'POST')
    open(out_wav, 'wb').write(wav)


def main():
    proc = start_engine()
    try:
        speakers = json.loads(req('/speakers'))
        if sys.argv[1] == 'list':
            rows = []
            for sp in speakers:
                for st in sp['styles']:
                    if st.get('type', 'talk') != 'talk': continue
                    try:
                        rows.append((mean_pitch(query(TEST, st['id'])), sp['name'], st['name'], st['id'], sp['speaker_uuid']))
                    except Exception as e:
                        print('skip', sp['name'], st['name'], e)
            for r in sorted(rows, reverse=True)[:25]:
                print('%.2f  %-14s %-10s id=%-3d %s' % r)
        elif sys.argv[1] == 'policy':
            info = json.loads(req('/speaker_info?' + urllib.parse.urlencode({'speaker_uuid': sys.argv[2]})))
            print(info['policy'])
        elif sys.argv[1] == 'make':
            style = int(sys.argv[2])
            lines = json.load(open(os.path.join(HERE, 'tools/voice_lines.json')))
            os.makedirs(os.path.join(HERE, 'voice'), exist_ok=True)
            for ru, ja in lines.items():
                h = hashlib.md5(ru.encode('utf-8')).hexdigest()
                wav = os.path.join(HERE, 'build', f'voice_{h}.wav'); os.makedirs(os.path.dirname(wav), exist_ok=True)
                synth(ja, style, wav)
                ogg = os.path.join(HERE, 'voice', h + '.ogg')
                subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', wav, '-af', 'loudnorm=I=-16:TP=-1.5',
                                '-ar', '44100', '-c:a', 'libvorbis', '-q:a', '5', ogg], check=True)
                os.remove(wav)
                print(h, ru, '->', ja)
    finally:
        if proc: proc.terminate()


main()
