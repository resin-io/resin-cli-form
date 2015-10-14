###
The MIT License

Copyright (c) 2015 Resin.io, Inc. https://resin.io.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
###

###*
# @module form
###

Promise = require('bluebird')
_ = require('lodash')
inquirer = require('inquirer')
visuals = require('resin-cli-visuals')
utils = require('./utils')

###*
# @summary Run a form description
# @function
# @public
#
# @param {Object[]} form - form description
# @param {Object} [options={}] - options
# @param {Object} [options.override] - overrides
#
# @returns {Promise<Object>} answers
#
# @example
# form.run [
# 	message: 'Processor'
# 	name: 'processorType'
# 	type: 'list'
# 	choices: [ 'Z7010', 'Z7020' ]
# ,
# 	message: 'Coprocessor cores'
# 	name: 'coprocessorCore'
# 	type: 'list'
# 	choices: [ '16', '64' ]
# ],
#
# 	# coprocessorCore will always be 64
# 	# Notice that the question will not be asked at all
# 	override:
# 		coprocessorCore: '64'
#
# .then (answers) ->
# 	console.log(answers)
###
exports.run = (form, options = {}) ->
	questions = utils.parse(form)

	Promise.reduce questions, (answers, question) ->

		# Since we now run `reduce` over the questions and run
		# inquirer inputs in an isolated way, `when` functions
		# no longer make sense to inquirer.
		# Therefore, we implement `when` checking manually
		# here based on `shouldPrompt`.
		if question.shouldPrompt? and not question.shouldPrompt(answers)
			return answers

		if _.has(options.override, question.name) and _.get(options.override, question.name)?
			answers[question.name] = options.override[question.name]
			return answers

		if question.type is 'drive'
			visuals.drive(question.message).then (drive) ->
				answers[question.name] = drive
				return answers
		else
			utils.prompt([ question ]).then (answer) ->
				return _.assign(answers, answer)
	, {}

###*
# @summary Run a single form question
# @function
# @public
#
# @param {Object} question - form question
# @returns {Promise<*>} answer
#
# @example
# form.ask
# 	message: 'Processor'
# 	type: 'list'
# 	choices: [ 'Z7010', 'Z7020' ]
# .then (processor) ->
# 	console.log(processor)
###
exports.ask = (question, callback) ->
	question.name ?= 'question'
	exports.run([ question ]).get(question.name)
