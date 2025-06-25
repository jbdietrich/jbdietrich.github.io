# Load shifting my dishwasher in 50(ish) lines of Python

2025-06-24

## tl;dr

Recently at [Electricity Maps](https://electricitymaps.com) we released [an API endpoint](https://portal.electricitymaps.com/docs/api#carbon-aware-scheduler) that makes it easy to figure out how best to consume electricity. You provide the API with information about when and where you're planning to use electricity and the system figures out how to optimize for things like:

- the least amount of CO2 emitted
- the largest share of renewable energy
- the smallest net load on the electricity grid

Within the company we've used the API to schedule some of our cloud compute workloads intelligently. That is super cool! But in my view this techonology's real potential lies in the fact that it's applicable to all types of consumption: from datacenters to EVs to humble home appliances. This post describes how I put that idea to the test by hooking it up to my own dishwasher.

## On load shifting

Adjusting when and where you consume electricity in response to information about the electricity system is known as "load shifting". Exactly how you shift your consumption depends on what you care about. For example, if you want to reduce cost, you'll start your consumption when when prices are lowest. If you care most about grid stability, you may time your usage to match the lowest demand on your local grid. Finally, if you care about reducing emissions how much of your electricity comes from rewewable sources.

1. Planned electricity consumption that you're able to move in time or space. Not all consumption can be shifted (you need to run your refrigerator at all times and you need your lights on when it's dark)
2. Some objective you want to optimize for (e.g. reducing carbon emissions)
3. A good forecast of the information you need to optimize for your objective (e.g. what will the carbon intensity of electricity be)

## On dishwashers

At the scale of my household the easiest thing to adjust is the dishwasher's<sup>1</sup> electricity consumption. This is because my dishwasher usage is chillingly predictable: I fill it every evening after dinner leaving a 10 hour window in which it can run before morning.

Additionally, like most appliances built in the last decade, the dishwasher can controlled from the internet. It's not clear whether this is a Good Thing™️ on balance but it's helpful for load shifting!

It adds up to the

- ✅ Planned electricity consumption that I'm able to move in time -> running the dishwasher
- ✅ Objective to optimize for -> reducing carbon emissions
- ✅ A good forecast -> 🪄 from the Electricity Maps API


## On load shifting my dishwasher

It only took me a couple of hours to connect my dishwasher to the Electricity Maps scheduling API. The following is a rough outline of the steps I took to do it.

### Setting up the plumbing

It turns out that I have a Bosch dishwasher (model number SMV4EDX17E/10). Bosch manages interactions with its smart appliances through a platform called Home Connect, which offers [a well-documented REST API](https://api-docs.home-connect.com). However, because the API uses OAuth2, I decided to use the [homeconnect](https://github.com/DavidMStraub/homeconnect) Python package to make authorization easier.

1. Download the [Home Connect](https://www.home-connect.com/us/en) app, set up an account, and link the account to my dishwasher (my wife had previously connected the dishwasher to our home network). I was able to see the dishwasher in the app once once my account was linked.

<img src="https://imagedelivery.net/GEsI1Cps_TzlnwLLGalXRQ/9d7f9b37-b3a0-461a-db0a-ed8d11b21200/public" width="50%" height="50%"/>


2. Set up an account on the [Home Connect Developer Portal](https://developer.home-connect.com). There I registered an register application (in this case). This gave me some values that are required to authorize requests: a "Client ID", "Client Secret", and "Redirect URL".

3. Write some code to authenticate and interact with the Home Connect API. I used . First, I created a `.env` file with the secrets I needed and then and a Python script to load the secrets into memory:

`.env`
```
OAUTHLIB_INSECURE_TRANSPORT=1 # necessary to allow the OAuth flow to use an http app locally
HC_CLIENT_ID=id_from_developer_portal
HC_CLIENT_SECRET=secret_from_developer_portal
HC_REDIRECT_URL=http://localhost:8000
EMAPS_TOKEN=api_token_from_electricity_maps # get an API token at https://portal.electricitymaps.com
```

`config.py`
```
from dotenv import load_dotenv
import os

load_dotenv()

HC_CLIENT_ID = os.getenv("HC_CLIENT_ID")
HC_CLIENT_SECRET = os.getenv("HC_CLIENT_SECRET")
HC_REDIRECT_URI = os.getenv("HC_REDIRECT_URI")
EMAPS_TOKEN = os.getenv("EMAPS_TOKEN")
```

4. Authorize my local Python script. First, I needed e function that returns a `HomeConnect` object for interacting with the Home Connect API, including the auth flow:

```
from config import HC_CLIENT_ID, HC_CLIENT_SECRET, HC_REDIRECT_URI
from homeconnect import HomeConnect
# ...

def get_home_connect():
    return HomeConnect(HC_CLIENT_ID, HC_CLIENT_SECRET, HC_REDIRECT_URI)
```

I also needed a function that produces URL that I can use to authorize the app. The function also redirects to a local server so I can read the auth code:

```
def get_auth_token():
    hc = get_home_connect()
    print(
        f"Visit the following URL in your browser to get the auth result: {hc.get_authurl()}"
    )

    port = 8000
    server_address = ("", port)
    httpd = HTTPServer(server_address, SimpleHTTPRequestHandler)
    httpd.serve_forever()
```

![]

Finally, a function that will store the authorized token in a local file for future calls to the API.

```
def save_auth_token(auth_result):
    hc = get_home_connect()
    hc.get_token(auth_result)
    print("Updated auth token in homeconnect_oauth_token.json")
```

The
### Using the Electricity Maps API to schedule the dishwasher

Once I was able to talk to the Home Connect API, the

1. Ask the Electricity Maps API to using the carbon aware scheduler API.

```
from config import EMAPS_TOKEN
import requests
# ...

METRIC_MAPPING = {
    "carbon-intensity": "flow-traced_carbon_intensity",
    "renewable-share": "flow-traced_renewable_share",
    "net-load": "net-load",
}

def get_start_time(window_start, window_end, optimization_metric="carbon-intensity"):
    headers = {"auth-token": EMAPS_TOKEN}
    data = {
        "duration": "PT4H",  # Eco cycle takes around 4 hours
        "startWindow": window_start,
        "endWindow": window_end,
        "locations": ["DK-DK1"],  # My EMaps zone, see https://portal.electricitymaps.com/docs/getting-started#geographical-coverage
        "optimizationMetric": METRIC_MAPPING[optimization_metric],
    }
    r = requests.post(
        "https://api.electricitymap.org/beta/carbon-aware-scheduler",
        headers=headers,
        data=data,
    )
    start_time = datetime.fromisoformat(r.json()["optimalStartTime"])
    print(
        f"To optimize for {' '.join(optimization_metric.split('-'))}, scheduling dishwasher to run at {start_time.strftime('%A, %B %d, %Y at %I:%M %p')}"
    )

    return start_time
```

1. Find a time to

## Next steps

Ultimately was. I wanted to see whether it was

## Conclusion

I published the code for this post to GitHub here. It's encouraging to see how easy it is to get going. There are a lot of caveats here:

- How big a difference does this actually make? There'
- What about measurement? Shouldn't
- Measurement

These
