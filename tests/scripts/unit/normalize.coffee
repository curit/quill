#= require mocha
#= require chai
#= require jquery
#= require underscore
#= require tandem/editor


describe('Normalize', ->
  describe('block', ->
    editor = new Tandem.Editor('editor-container')
    tests = [{
      name: 'initialize empty document'
      before: ''
      expected: '<div><br></div>'
    }, {
      name: 'remove br from non-empty lines'
      before: 
        '<div>
          <br>
        </div>
        <div>
          <span>Text</span>
          <br>
        </div>'
      expected: 
        '<div>
          <br>
        </div>
        <div>
          <span>Text</span>
        </div>'
    }, {
      name: 'break block elements'
      before: 
        '<div>
          <div>
            <span>Hey</span>
          </div>
          <h1>
            <span>What</span>
          </h1>
        </div>'
      expected: 
        '<div>
          <span>Hey</span>
        </div>
        <div>
          <span>What</span>
        </div>'
    }, {
      name: 'break on br tags'
      before: 
        '<div>
          <span>Text</span>
          <br />
          <b>Bold</b>
          <br />
          <i>Italic</i>
        </div>'
      expected: 
        '<div>
          <span>Text</span>
        </div>
        <div>
          <b>Bold</b>
        </div>
        <div>
          <i>Italic</i>
        </div>'
    }, {
      name: 'remove redundant block elements'
      before:
        '<div>
          <div>
            <span>Hey</span>
          </div>
        </div>
        <div>
          <div>
            <div>
              <div>
                <span>What</span>
              </div>
            </div>
          </div>
        </div>'
      expected:
        '<div>
          <span>Hey</span>
        </div>
        <div>
          <span>What</span>
        </div>'
    }, {
      name: 'break list elements'
      before: 
        '<ul>
          <li>One</li>
          <li>Two</li>
          <li>Three</li>
        </ul>'
      expected:
        '<ul>
          <li>
            <span>One</span>
          </li>
        </ul>
        <ul>
          <li>
            <span>Two</span>
          </li>
        </ul>
        <ul>
          <li>
            <span>Three</span>
          </li>
        </ul>'
    }, {
      name: 'split block level tags within elements'
      before:
        '<div>
          <b>
            <i>What</i>
            <div>
              <s>Strike</s>
            </div>
            <u>Underline</u>
          </b>
        </div>'
      expected:
        '<div>
          <b>
            <i>What</i>
          </b>
        </div>
        <div>
          <b>
            <s>Strike</s>
          </b>
        </div>
        <div>
          <b>
            <u>Underline</u>
          </b>
        </div>'  
    }, {
      name: 'should correctly break inner br tag'
      before:
        '<div>
          <span>
            <br>
          </span>
        </div>'
      expected:
        '<div>
          <br>
        </div>'  
    }]

    _.each(tests, (test) ->
      it('should ' + test.name, ->
        editor.doc.root.innerHTML = Tandem.Utils.cleanHtml(test.before)
        editor.doc.buildLines()
        expect(Tandem.Utils.cleanHtml(editor.doc.root.innerHTML)).to.equal(Tandem.Utils.cleanHtml(test.expected))
      )
    )
  )


  
  describe('elements', ->
    editor = new Tandem.Editor('editor-container')
    tests = [{
      name: 'tranform equivalent styles'
      before:
        '<div>
          <strong>Strong</strong>
          <del>Deleted</del>
          <em>Emphasis</em>
          <strike>Strike</strike>
          <b>Bold</b>
          <i>Italic</i>
          <s>Strike</s>
          <u>Underline</u>
        </div>'
      expected:
        '<div>
          <b>Strong</b>
          <s>Deleted</s>
          <i>Emphasis</i>
          <s>Strike</s>
          <b>Bold</b>
          <i>Italic</i>
          <s>Strike</s>
          <u>Underline</u>
        </div>'
    }, {
      name: 'merge adjacent equal nodes'
      before:
        '<div>
          <b>Bold1</b>
          <b>Bold2</b>
        </div>'
      expected:
        '<div>
          <b>Bold1Bold2</b>
        </div>'
    }, {
      name: 'merge adjacent equal spans'
      before:
        '<div>
          <span class="font-color red">
            <span class="font-background blue">Red1</span>
          </span>
          <span class="font-color red">
            <span class="font-background blue">Red2</span>
          </span>
        </div>'
      expected:
        '<div>
          <span class="font-color red">
            <span class="font-background blue">Red1Red2</span>
          </span>
        </div>'
    }, {
      name: 'do not merge adjacent unequal spans'
      before:
        '<div>
          <span class="font-size huge">Huge</span>
          <span class="font-size large">Large</span>
        </div>'
      expected:
        '<div>
          <span class="font-size huge">Huge</span>
          <span class="font-size large">Large</span>
        </div>'
    }, {
      name: 'remove redundant attribute elements'
      before: 
        '<div>
          <b>
            <i>
              <b>Bolder</b>
            </i>
          </b>
        </div>'
      expected:
        '<div>
          <b>
            <i>Bolder</i>
          </b>
        </div>'
    }, {
      name: 'remove redundant elements'
      before: 
        '<div>
          <span>
            <br>
          <span>
        </div>
        <div>
          <span>
            <span>Span</span>
          <span>
        </div>'
      expected: 
        '<div>
          <br>
        </div>
        <div>
          <span>Span</span>
        </div>'
    }, {
      name: 'wrap text node'
      before: 
        '<div>Hey</div>'
      expected:
        '<div>
          <span>Hey</span>
        </div>'
    }, {
      name: 'wrap text node next to element node'
      before: 
        '<div>Hey<b>Bold</b></div>'
      expected:
        '<div>
          <span>Hey</span>
          <b>Bold</b>
        </div>'
    }]
    
    _.each(tests, (test) ->
      it('should ' + test.name, ->
        editor.doc.root.innerHTML = Tandem.Utils.cleanHtml(test.before, true)
        editor.doc.buildLines()
        expect(Tandem.Utils.cleanHtml(editor.doc.root.innerHTML)).to.equal(Tandem.Utils.cleanHtml(test.expected))
      )
    )
  )
)