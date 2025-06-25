# Load shifting my dishwasher in 50(ish) lines of Python

2025-06-25

## tl;dr

Recently at [Electricity Maps](https://electricitymaps.com) we released [an API endpoint](https://portal.electricitymaps.com/docs/api#carbon-aware-scheduler) that makes it easy to figure out how best to consume electricity. You provide the API with information about when and where you're planning to use electricity and the system figures out how to optimize for things like:

- the least amount of CO2 emitted
- the largest share of renewable energy
- the smallest net load on the electricity grid

Within the company we've used the API to schedule some of our cloud compute workloads intelligently. That is super cool! But in my view this techonology's real potential lies in the fact that it's applicable to all types of consumption: from datacenters to EVs to humble home appliances. This post describes how I put that idea to the test by hooking it up to my own dishwasher.

## On load shifting

Adjusting when and/or where you consume electricity in response to information about the electricity system is known as "load shifting". Exactly how you shift your consumption depends on what you care about. For example, if you want to reduce cost, you'll start your consumption when when prices are lowest. If you care most about grid stability, you may time your usage to match the lowest demand on your local grid. Finally, if you care about reducing emissions how much of your electricity comes from rewewable sources.

In order to load shift, you need at least three things:

1. Planned electricity usage that you're able to move in time or space. Not all usage can be shifted (e.g. you need to run your refrigerator at all times, you turn lights on when it's dark, etc...)
2. Some goal you want to optimize for (e.g. reducing carbon emissions, lowering costs)
3. A (preferably good) forecast containing the information you need to optimize for your goal (i.e. what will the price of electricity be over the next 24 hours)

## On dishwashers

It turns out that in my house the easiest thing to adjust is the electricity consumption associated with my dishwasher<sup><a href="#footnote_1">1</a></sup>. This is because my dishwasher usage is alarmingly predictable: I fill it every evening after dinner, leaving a 10 hour window during which it can run before morning. Also, like most appliances built in the last decade, my dishwasher can be controlled from the internet. It's not clear whether this is a Good Thing™️ on balance but it's helpful for load shifting!

Given my dishwasher's capabilities and the way I use it, I have the necessary conditions for load shifting:

- ✅ Planned electricity consumption that I'm able to move in time -> running the dishwasher
- ✅ Objective to optimize for -> reducing carbon emissions
- ✅ A good forecast -> 🪄 from the Electricity Maps API


## On load shifting my dishwasher

I was pleasantly surprised that it only took me a couple of hours to connect my dishwasher to the Electricity Maps scheduling API. I spent most of that time figuring out how to interact with the dishwasher programmatically. The following is a rough outline of the steps I took to do it.

### Setting up the plumbing

I have a Bosch dishwasher (model number SMV4EDX17E/10 to be exact). It turns out that Bosch manages interactions with its smart appliances through a platform called Home Connect, which offers [a well-documented REST API](https://api-docs.home-connect.com). However, because the API uses OAuth2, I decided to use the [homeconnect](https://github.com/DavidMStraub/homeconnect) Python package to make the authorization process easier. I ended up doing the following:

1. Download the [Home Connect](https://www.home-connect.com/us/en) app, set up an account, and link the account to my dishwasher (my wife had previously connected the dishwasher to our home network). I was able to see the dishwasher in the app once once my account was linked.

    <img src="https://imagedelivery.net/GEsI1Cps_TzlnwLLGalXRQ/9d7f9b37-b3a0-461a-db0a-ed8d11b21200/public" width="20%" height="20%" style="margin: auto; display: block;"/>

2. Set up an account on the [Home Connect Developer Portal](https://developer.home-connect.com). There I registered an register application (in this case). This gave me some values that are required to authorize requests: a "Client ID", "Client Secret", and "Redirect URL".

   <img src="https://imagedelivery.net/GEsI1Cps_TzlnwLLGalXRQ/ddeb296e-0970-4800-3bf2-64cb9d149700/public" width="40%" height="40%" style="margin: auto; display: block;" />

3. Write some code to authenticate and interact with the Home Connect API. I used . First, I created a `.env` file with the secrets I needed and then and a Python script to load the secrets into memory:

    `.env`

    <pre>
    OAUTHLIB_INSECURE_TRANSPORT=1 # necessary to allow the OAuth flow to use an http app locally
    HC_CLIENT_ID=id_from_developer_portal
    HC_CLIENT_SECRET=secret_from_developer_portal
    HC_REDIRECT_URL=http://localhost:8000
    EMAPS_TOKEN=api_token_from_electricity_maps # get an API token at https://portal.electricitymaps.com
    </pre>

    `config.py`

    <pre>
    from dotenv import load_dotenv
    import os

    load_dotenv()

    HC_CLIENT_ID = os.getenv("HC_CLIENT_ID")
    HC_CLIENT_SECRET = os.getenv("HC_CLIENT_SECRET")
    HC_REDIRECT_URI = os.getenv("HC_REDIRECT_URI")
    EMAPS_TOKEN = os.getenv("EMAPS_TOKEN")
    </pre>

4. Authorize my local Python script. First, I needed a function that returns a `HomeConnect` object for interacting with the Home Connect API, including engaging with the auth flow:

    `hc.py`

    <pre>
    from config import HC_CLIENT_ID, HC_CLIENT_SECRET, HC_REDIRECT_URI
    from homeconnect import HomeConnect
    # ...

    def get_home_connect():
        return HomeConnect(HC_CLIENT_ID, HC_CLIENT_SECRET, HC_REDIRECT_URI)
    </pre>

    I also needed a function that produces URL that I can use to authorize the app. The function also redirects to a local server so I can read the auth code:

    `hc.py`

    <pre>
    def get_auth_token():
        hc = get_home_connect()
        print(
            f"Visit the following URL in your browser to get the auth result: {hc.get_authurl()}"
        )

        port = 8000
        server_address = ("", port)
        httpd = HTTPServer(server_address, SimpleHTTPRequestHandler)
        httpd.serve_forever()
    </pre>

    Finally, a function that stores the authorized token in a local file for future calls to the API.

    <pre>
    def save_auth_token(auth_result):
        hc = get_home_connect()
        hc.get_token(auth_result)
        print("Updated auth token in homeconnect_oauth_token.json")
    </pre>

5. Run the code above and authorize the app to get a valid auth token:

    <pre>
        ~/code/loadshifting-dishes [main] 🧨 uv run hc.py -print-auth-url
        Visit the following URL in your browser to get the auth result: https://api.home-connect.com/security/oauth/authorize?response_type=code&client_id=123XYZ&state=456XYZ
        127.0.0.1 - - [25/Jun/2025 11:36:00] "GET /?code=xxx&state=xxx&grant_type=authorization_code HTTP/1.1" 200
    </pre>

    <img src="https://imagedelivery.net/GEsI1Cps_TzlnwLLGalXRQ/1b504e8b-83bf-4148-1f28-7a0e574f3300/public" width="40%" height="40%" style="margin: auto; display: block;" />

    <pre>
        ~/code/loadshifting-dishes [main] 🧨 uv run hc.py --save-auth-token "http://localhost:8000/?code=xxx&&state=456XYZ&grant_type=authorization_code"
        Updated auth token in homeconnect_oauth_token.json
    </pre>

### Using the Electricity Maps API to schedule the dishwasher

Once I was able to talk to the Home Connect API, I had to:

- Find the optimal time to run the dis based on my availability window
- Shchedule the dishwasher to run at that time

1. Get the Electricity Maps API to tell me when to run the dishwasher using the scheduler API.

    `main.py`

    <pre>
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
            "duration": "PT4H",  # Eco cycle takes around 4 hours. This is the criminally underused but super helpful ISO duration format
            "startWindow": window_start,
            "endWindow": window_end,
            "locations": ["DK-DK1"],  # My EMaps "zone", see https://portal.electricitymaps.com/docs/getting-started#geographical-coverage
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
    </pre>

2. Write some code to schedule a time to run the dishwasher.

    `main.py`

    <pre>
    from datetime import datetime
    from hc import get_home_connect
    # ...

    def start_dishwasher(start_time):
        hc = get_home_connect()
        hc.token_load()
        dishwasher = next(a for a in hc.get_appliances() if a.name == "Dishwasher")
        now = datetime.now(ZoneInfo("UTC"))

        seconds_until_start = int((start_time - now).total_seconds())
        options = [
            {"key": "BSH.Common.Option.StartInRelative", "value": seconds_until_start}
        ]

        dishwasher.start_program("Dishcare.Dishwasher.Program.Eco50", options=options) # ECO program
    </pre>

3. Success! My diswhasher is scheduled at the time that Electricty Maps suggested and this fact is reflected in immediately the Home Connect app.

    <pre>
    ~/code/loadshifting-dishes [main] 🧨 uv run main.py --window-start "2025-06-25T19:00:00Z" --window-end  "2025-06-26T06:00:00Z"
    To optimize for carbon intensity, scheduling dishwasher to run at Thursday, June 26, 2025 at 02:00 AM
    </pre>

    <img src="https://imagedelivery.net/GEsI1Cps_TzlnwLLGalXRQ/f62adb86-5c02-4c36-881a-1c7597d5a000/public" width="20%" height="20%" style="margin: auto; display: block;" />

## Conclusions and next steps

Ultimately this is a toy example that only gestures towards what's possible. I'm not a "home automation person" but I'm aware of mature software packages like [Home Assistant](https://www.home-assistant.io/) that could be used instead of rolling my own Python script. Failing that, there's probably a cool Lovable app to build on top of the proof-of-concept here. There are also ways to do this entirely locally instead of involving a cloud service.

It's also [fair to question](https://www.linkedin.com/feed/update/urn:li:activity:7341836147959996416?commentUrn=urn%3Ali%3Acomment%3A%28activity%3A7341836147959996416%2C7342102791303163905%29&replyUrn=urn%3Ali%3Acomment%3A%28activity%3A7341836147959996416%2C7342880249270927360%29&dashCommentUrn=urn%3Ali%3Afsd_comment%3A%287342102791303163905%2Curn%3Ali%3Aactivity%3A7341836147959996416%29&dashReplyUrn=urn%3Ali%3Afsd_comment%3A%287342880249270927360%2Curn%3Ali%3Aactivity%3A7341836147959996416%29) the real impact of load shifting. At Electricity Maps we've learned a lot about the topic, particularly in the context of data center operations. We even have [a webinar](https://ww2.electricitymaps.com/webinars/webinar-carbon-aware-it?utm_source=linkedin&utm_medium=social&utm_campaign=it-webinar-reminder) in which we dive deep into the topic. The good news is that there is a scale at which load shifting activities make a difference to grid operations (this brings with it [its own consequences](https://es.catapult.org.uk/insight/the-emerging-ev-overnight-demand-peak-claire-rowland/)).

Putting these considerations aside, what encourages me is how _simple_ it is to build an API integration on top of what is an increasingly complex electricity system. It's true that as more data about the electricity system - especially forecasts - become available and as more flexibile consumption (e.g. EVs, battery storage) is added to the grid, there are more opportunities to optimize. The key, though, is the quality and simplicity of the interfaces available to us: we won't unlock optmization potential unless we can interact with the electricity system easily and reliably.

## Resources

- [Full code used in this post](https://github.com/jbdietrich/loadshifting-dishes) (GitHub)
- [Electricity Maps API documentation](https://portal.electricitymaps.com/)
- [Webinar](https://ww2.electricitymaps.com/webinars/webinar-carbon-aware-it?utm_source=linkedin&utm_medium=social&utm_campaign=it-webinar-reminder) discussing the impact of load shifting in the context of IT operations
- [Home Connect](https://www.home-connect.com/)
- [Home Assistant](https://www.home-assistant.io/)

<div id="footnote_1">1. I also own an EV whose charging app for provides some load minimal load-shifting features. More on that in a future post!</div>
