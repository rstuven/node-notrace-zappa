{Consumer} = require 'notrace'

consumer = require('zappa').app ->

    @enable 'default layout', 'serve jquery', 'serve sammy'#, 'minify'

    @on connection: ->
        @consumer.stop() if @consumer?
        @consumer = new Consumer

        @consumer.start 'p..random_walk', (subject) =>
            subject.subscribe (sample) =>
                @emit sample: {module: sample.module, arg0: sample.args[0]}

        #@consumer.start 'p..random_walk',
            #window: '10000,500'
            #group: 'module'
            #aggregate: 'average(args[0])'
            #callback: (sample) =>
                #sample.forEach (item) =>
                    #@emit sample: {module: item.key, arg0: item.average}

    @client '/index.js': ->
        @connect()

        @on sample: ->
            updateSample @data.module, @data.arg0

        $ ->
            options =
                series: { shadowSize: 0 }
                yaxis: { min: -1024, max: 1024 }
                xaxis: { show: false }

            totalPoints = 300
            data = {}

            getData = ->
                ret = []
                for key, series of data
                    ret.push
                        label: key
                        data: ([i, series[i]] for i in [0...series.length])
                console.log ret
                ret

            addData = (key, value) ->
                series = data[key]
                series = data[key] = (0 for i in [0...totalPoints]) if not series?
                series.shift() if series.length > 0
                series.push value

            window.updateSample = (key, value) ->
                addData key, value
                #plot.setData getData()
                #plot.draw()
                plot = $.plot $('#placeholder'), getData(), options

            plot = $.plot $('#placeholder'), getData(), options

    @get '/': ->
        @render 'index'

    @view index: ->
        @title = 'NoTrace Consumer'
        @scripts = ['/socket.io/socket.io', '/zappa/jquery', '/zappa/sammy', 'http://people.iola.dk/olau/flot/jquery.flot', '/zappa/zappa', '/index']

        h1 @title
        div id:"placeholder", style:"width:600px;height:300px;"

consumer.app.listen 8083
