import React, { Component } from 'react'
import { ScrollView, StyleSheet, Text, View } from 'react-native'

import Button from './Button'

import branch from 'react-native-branch'

const defaultBUO = {
  title: 'wallo'
}

class BranchMethods extends Component {

  buo = null

  state = {
    results: [],
  }

  componentWillMount() {
    branch.subscribe(({params, uri, error}) => {
      console.log('inbound link', params, uri, error)
      if (error) this.addResult('error', 'subscribe', error)
      else this.addResult('success', 'subscribe', params || uri)
    })
  }

  createBranchUniversalObject = async () => {
    try {
      let result = await branch.createBranchUniversalObject('abc', defaultBUO)
      this.buo = result
      console.log('createBranchUniversalObject', result)
      this.addResult('success', 'createBranchUniversalObject', result)
    } catch (err) {
      console.log('createBranchUniversalObject err', err.toString())
      this.addResult('error', 'createBranchUniversalObject', err.toString())
    }
  }

  generateShortUrl = async () => {
    if (!this.buo) await this.createBranchUniversalObject()
    try {
      let result = await this.buo.generateShortUrl()
      console.log('generateShortUrl', result)
      this.addResult('success', 'generateShortUrl', result)
    } catch (err) {
      console.log('generateShortUrl err', err.toString())
      this.addResult('error', 'generateShortUrl', err.toString())
    }
  }

  registerView = async () => {
    if (!this.buo) await this.createBranchUniversalObject()
    try {
      let result = await this.buo.registerView()
      console.log('registerView', result)
      this.addResult('success', 'registerView', result)
    } catch (err) {
      console.log('registerView err', err.toString())
      this.addResult('error', 'registerView', err.toString())
    }
  }

  listOnSpotlight = async () => {
    if (!this.buo) await this.createBranchUniversalObject()
    try {
      let result = await this.buo.listOnSpotlight()
      console.log('listOnSpotlight', result)
      this.addResult('success', 'listOnSpotlight', result)
    } catch (err) {
      console.log('listOnSpotlight err', err.toString())
      this.addResult('error', 'listOnSpotlight', err.toString())
    }
  }

  showShareSheet = async () => {
    if (!this.buo) await this.createBranchUniversalObject()
    try {
      let result = await this.buo.showShareSheet()
      console.log('showShareSheet', result)
      this.addResult('success', 'showShareSheet', result)
    } catch (err) {
      console.log('showShareSheet err', err.toString())
      this.addResult('error', 'showShareSheet', err.toString())
    }
  }

  redeemRewards = async (bucket) => {
    try {
      let result = await branch.redeemRewards(5, bucket)
      console.log('redeemRewards', result)
      this.addResult('success', 'redeemRewards', result)
    } catch (err) {
      console.log('redeemRewards err', {...err}, err.message, err.toString())
      this.addResult('error', 'redeemRewards', err.toString())
    }
  }

  loadRewards = async() => {
    try {
      let result = await branch.loadRewards()
      console.log('loadRewards', result)
      this.addResult('success', 'loadRewards', result)
    } catch (err) {
      console.log('loadRewards err', err.toString())
      this.addResult('error', 'loadRewards', err.toString())
    }
  }

  getCreditHistory = async() => {
    try {
      let result = await branch.getCreditHistory()
      console.log('getCreditHistory', result)
      this.addResult('success', 'getCreditHistory', result)
    } catch (err) {
      console.log('getCreditHistory err', err.toString())
      this.addResult('error', 'getCreditHistory', err.toString())
    }
  }

  addResult(type, slug, payload) {
    let result = { type, slug, payload }
    this.setState({
      results: [result, ...this.state.results].slice(0, 10)
    })
  }

  render() {
    return (
      <View style={styles.container}>
        <View style={styles.resultsContainer}>
          <Text style={styles.header}>RESULTS</Text>
          <ScrollView style={styles.scrollContainer}>
            {this.state.results.length === 0 && <Text>No Results yet, run a method below</Text>}
            {this.state.results.map((result, i) => {
              return (
                <View key={i} style={styles.result}>
                  <Text style={result.type === 'success' ? styles.textSucccess : styles.textError}>{`${result.slug} (${result.type})`}</Text>
                  <Text style={styles.textSmall}>{JSON.stringify(result.payload, null, 2)}</Text>
                </View>
              )
            })}
          </ScrollView>
        </View>
        <Text style={styles.header}>METHODS</Text>
        <ScrollView style={styles.buttonsContainer}>
          <Button onPress={this.createBranchUniversalObject}>createBranchUniversalObject</Button>
          <Button onPress={this.generateShortUrl}>generateShortUrl</Button>
          <Button onPress={this.registerView}>registerView</Button>
          <Button onPress={this.listOnSpotlight}>listOnSpotlight</Button>
          <Button onPress={this.showShareSheet}>showShareSheet</Button>
          <Button onPress={this.redeemRewards.bind(this, '')}>redeemRewards</Button>
          <Button onPress={this.redeemRewards.bind(this, 'testBucket')}>redeemRewards (with bucket)</Button>
          <Button onPress={this.loadRewards}>loadRewards</Button>
          <Button onPress={this.getCreditHistory}>getCreditHistory</Button>
        </ScrollView>
      </View>
    )
  }
}

export default BranchMethods

const styles = StyleSheet.create({
  container: {
    marginTop: 30,
    flex: 1,
  },
  header: {
    backgroundColor: '#ccc',
    padding: 5,
    paddingLeft: 10,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: '#aaa',
    fontSize: 10,
    fontWeight: 'bold',
  },
  resultsContainer: {
    flex: 2,
  },
  scrollContainer: {
    padding: 5,
  },
  result: {
    padding: 5,
  },
  textSmall: {
    fontSize: 10,
  },
  textSucccess: {
    color: '#6c9c5d',
  },
  textError: {
    color: '#a03d31',
  },
  buttonsContainer: {
    flex: 1,
  }
})
