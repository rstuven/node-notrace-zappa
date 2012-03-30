{Consumer} = require 'notrace'

consumer = require('zappa').app ->

    @enable 'default layout', 'serve jquery', 'serve sammy'#, 'minify'

    @on connection: ->
        @consumer.stop() if @consumer?
        @consumer = new Consumer
        @consumer.start 'p..random_walk',
            #window: '10000,1000'
            window: '1000'
            aggregate: 'lquantize(args[0];-1024;1024;128)'
            callback: (sample) =>
                @emit sample: sample.lquantize

    @client '/index.js': ->
        @connect()

        @on sample: ->
             updateHeatmap @data

        COLUMNS = 40
        CELL_SIZE = 15
        $ ->
            columns = []
            maxCount = 0

            setup = (rows) ->
                return if columns.length > 0
                row = (0 for r in [1..rows])
                columns = (rows for col in  [1..COLUMNS])

            window.updateHeatmap = (lquantize) ->
                counts = lquantize.counts
                max = lquantize.maxCount
                maxCount = max if maxCount < max # adapt to historical max in this session
                setup counts.length
                columns.shift()
                counts = counts.map (x) -> x/maxCount if maxCount isnt 0
                columns.push counts
                draw()

            draw = ->
                canvas = document.getElementById('canvas')
                return if not canvas.getContext?
                ctx = canvas.getContext '2d'
                for col in [0...columns.length]
                    rows = columns[col]
                    for row in [0...rows.length]
                        value = rows[row]
                        ctx.fillStyle = "rgb(#{value * 255}, 0, 0)"
                        ctx.fillRect col * CELL_SIZE, ((rows.length - 1) * CELL_SIZE) - (row * CELL_SIZE), CELL_SIZE, CELL_SIZE

    @get '/': ->
        @render 'index'

    @view index: ->
        @title = 'NoTrace Consumer'
        @scripts = ['/socket.io/socket.io', '/zappa/jquery', '/zappa/sammy', 'http://people.iola.dk/olau/flot/jquery.flot', '/zappa/zappa', '/index']

        h1 @title
        canvas id: 'canvas', width: 1024, height: 512

consumer.app.listen 8083
